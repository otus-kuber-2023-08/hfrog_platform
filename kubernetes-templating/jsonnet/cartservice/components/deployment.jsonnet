local env = {
  name: std.extVar('qbec.io/env'),
  namespace: std.extVar('qbec.io/defaultNs'),
};
local p = import '../params.libsonnet';
local params = p.components.deployment;

{
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: params.name,
    namespace: env.namespace,
  },
  spec: {
    selector: {
      matchLabels: {
        app: params.name,
      },
    },
    template: {
      metadata: {
        labels: { app: params.name },
      },
      spec: {
        containers: [
          {
            name: 'server',
            image: params.image,
            ports: [
              {
                containerPort: params.containerPort,
              },
            ],
            env: params.env,
            readinessProbe: { initialDelaySeconds: 15, exec: { command: ["/bin/grpc_health_probe", "-addr=:" + params.containerPort, "-rpc-timeout=5s"], }, },
            livenessProbe: self.readinessProbe { periodSeconds: 10 },
          },
        ],
      },
    },
  },
}
