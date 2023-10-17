#!/usr/bin/env python3
# vim: sw=4

import kopf
import yaml
import kubernetes
import time
from jinja2 import Environment, FileSystemLoader
from yaml import Loader


def wait_until_job_end(jobname):
    api = kubernetes.client.BatchV1Api()
    job_finished = False
    jobs = api.list_namespaced_job('default')
    while not job_finished and any(job.metadata.name == jobname for job in jobs.items):
        time.sleep(1)
        jobs = api.list_namespaced_job('default')
        for job in jobs.items:
            if job.metadata.name == jobname:
                print(f'job with name {jobname} found, waiting until end')
                if job.status.succeeded == 1:
                    print(f'job with {jobname} is successful')
                    job_finished = True


def render_template(filename, vars_dict):
    env = Environment(loader=FileSystemLoader('./templates'))
    template = env.get_template(filename)
    yaml_manifest = template.render(vars_dict)
    json_manifest = yaml.load(yaml_manifest, Loader=Loader)
    return json_manifest


def delete_successful_jobs(mysql_instance_name):
    print('start deletion')
    api = kubernetes.client.BatchV1Api()
    jobs = api.list_namespaced_job('default')
    for job in jobs.items:
        jobname = job.metadata.name
        if jobname in [f'backup-{mysql_instance_name}-job', f'restore-{mysql_instance_name}-job', f'change-password-{mysql_instance_name}-job']:
            if job.status.succeeded == 1:
                api.delete_namespaced_job(jobname, 'default', propagation_policy='Background')


@kopf.on.create('otus.homework', 'v1', 'mysqls')
# Функция, которая будет запускаться при создании объектов тип MySQL:
def mysql_on_create(body, patch, **kwargs):
    name = body['metadata']['name']
    image = body['spec']['image']  # cохраняем в переменные содержимое описания MySQL из CR
    password = body['spec']['password']
    database = body['spec']['database']
    storage_size = body['spec']['storage_size']

    # Генерируем JSON манифесты для деплоя
    persistent_volume_claim = render_template('mysql-pvc.yml.j2',
        {'name': name, 'storage_size': storage_size})
    service = render_template('mysql-service.yml.j2', {'name': name})
    deployment = render_template('mysql-deployment.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})
    restore_job = render_template('restore-job.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})

    # Определяем, что созданные ресурсы являются дочерними к управляемому CustomResource:
    kopf.append_owner_reference(persistent_volume_claim, owner=body)
    kopf.append_owner_reference(service, owner=body)
    kopf.append_owner_reference(deployment, owner=body)
    kopf.append_owner_reference(restore_job, owner=body)
    # ^ Таким образом при удалении CR удалятся все, связанные с ним pv, pvc, svc, deployments

    api = kubernetes.client.CoreV1Api()
    # Создаем mysql PVC:
    api.create_namespaced_persistent_volume_claim('default', persistent_volume_claim)
    # Создаем mysql SVC:
    api.create_namespaced_service('default', service)
    # Создаем mysql Deployment:
    api = kubernetes.client.AppsV1Api()
    api.create_namespaced_deployment('default', deployment)

    # Cоздаем PVC и PV для бэкапов:
    try:
        backup_pv = render_template('backup-pv.yml.j2', {'name': name})
        api = kubernetes.client.CoreV1Api()
        api.create_persistent_volume(backup_pv)
    except kubernetes.client.rest.ApiException:
        pass

    try:
        backup_pvc = render_template('backup-pvc.yml.j2', {'name': name})
        api = kubernetes.client.CoreV1Api()
        api.create_namespaced_persistent_volume_claim('default', backup_pvc)
    except kubernetes.client.rest.ApiException:
        pass

    # Пытаемся восстановиться из backup
    try:
        api = kubernetes.client.BatchV1Api()
        api.create_namespaced_job('default', restore_job)
    except kubernetes.client.rest.ApiException:
        pass
    patch.status['Kopf'] = 'Init'


@kopf.on.field('otus.homework', 'v1', 'mysqls', field='spec.password')
def change_password(body, old, new, **kwargs):
    name = body['metadata']['name']
    image = body['spec']['image']
    database = body['spec']['database']

    delete_successful_jobs(name)
    api = kubernetes.client.BatchV1Api()
    change_password_job = render_template('change-password-job.yml.j2', {
        'name': name,
        'image': image,
        'old_password': old,
        'new_password': new,
        'database': database})
    api.create_namespaced_job('default', change_password_job)
    wait_until_job_end(f'change-password-{name}-job')
    kopf.info(body, reason='Change password', message='changing database password')


@kopf.on.resume('otus.homework', 'v1', 'mysqls')
def mysql_on_resume(body, spec, **kwargs):
    kopf.info(body, reason='Resume', message='Resume handler is called')


@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_object_make_backup(body, **kwargs):
    name = body['metadata']['name']
    image = body['spec']['image']
    password = body['spec']['password']
    database = body['spec']['database']

    delete_successful_jobs(name)
    # Cоздаем backup job:
    api = kubernetes.client.BatchV1Api()
    backup_job = render_template('backup-job.yml.j2', {
        'name': name,
        'image': image,
        'password': password,
        'database': database})
    api.create_namespaced_job('default', backup_job)
    wait_until_job_end(f'backup-{name}-job')
    kopf.info(body, reason='Delete', message='mysql and its children resources deleted')


def does_job_exist(jobname):
    api = kubernetes.client.BatchV1Api()
    for job in api.list_namespaced_job('default').items:
        if job.metadata.name == jobname:
            return True
    return False


def is_job_succeeded(jobname):
    api = kubernetes.client.BatchV1Api()
    for job in api.list_namespaced_job('default').items:
        if job.metadata.name == jobname and job.status.succeeded == 1:
            return True
    return False


@kopf.timer('otus.homework', 'v1', 'mysqls', interval=1)
def get_jobs_status(body, spec, patch, **kwargs):
    name = body['metadata']['name']
    if does_job_exist(f'backup-{name}-job') and not is_job_succeeded(f'backup-{name}-job'):
        patch.status['Kopf'] = 'Doing backup'
    if does_job_exist(f'restore-{name}-job') and not is_job_succeeded(f'restore-{name}-job'):
        patch.status['Kopf'] = 'Doing restore'
    if does_job_exist(f'change-password-{name}-job') and not is_job_succeeded(f'change-password-{name}-job'):
        patch.status['Kopf'] = 'Changing password'
    else:
        patch.status['Kopf'] = 'Ready'
