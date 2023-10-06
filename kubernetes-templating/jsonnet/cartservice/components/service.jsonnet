local env = {
  name: std.extVar('qbec.io/env'),
  namespace: std.extVar('qbec.io/defaultNs'),
};
local p = import '../params.libsonnet';
local params = p.components.service;

{
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: params.name,
    namespace: env.namespace,
  },
  spec: {
    type: 'ClusterIP',
    selector: {
      app: params.name,
    },
    ports: [
      { name: 'grpc', port: params.port, targetPort: params.targetPort, },
    ],
  },
}
