
local kube = import 'https://raw.githubusercontent.com/kube-libsonnet/kube-libsonnet/v1.22.2/kube.libsonnet';

local microservice(name) = {
  deployment: kube.Deployment(name) {
    local service_port = 50051,
    local service_name = "grpc",
    metadata+: {
      labels+: {
        app: name,
      }
    },
    spec+: {
      minReadySeconds:: null,
      template+: {
        spec+: {
          containers_+: {
            server: kube.Container("server") {
              name: "server",
              image: "gcr.io/google-samples/microservices-demo/" + name + ":v0.1.3",
              env: [
                { name: "PORT", value: std.toString(service_port), },
              ],
              ports: [
                {
                  name: service_name,
                  containerPort: service_port,
                },
              ],
              readinessProbe: {
                exec: {
                  command: [
                    "/bin/grpc_health_probe",
                    "-addr=:" + std.toString(50051),
                  ],
                },
              },
              livenessProbe: self.readinessProbe,
              resources: {
                requests: {
                  cpu: "100m",
                  memory: "64Mi",
                },
                limits: {
                  cpu: "200m",
                  memory: "128Mi",
                },
              },
            },
          },
        },
      },
    },
  },

  service: kube.Service(name) {
    target_pod: $.deployment.spec.template,
    metadata+: {
      labels+: {
        app: name,
      }
    },
  },
};
  
{
  paymentservice: microservice("paymentservice"),
  shippingservice: microservice("shippingservice"),
}
