# Grafana Setup Guide

## 🎯 Access Grafana

### URL
- **Local Access**: http://localhost:30200
- **Node IP Access**: http://192.168.97.4:30200

### Credentials
- **Username**: `admin`
- **Password**: `TWhi6gjUhB9d6eP7FrTnxs0At9ek2rhnqyFS7NLe`

## 📊 Available Dashboard

A custom dashboard has been created for your House Price Predictor application:

### Dashboard Name: "House Price Predictor - Application Monitoring"

This dashboard includes:
1. **CPU Usage** - Real-time CPU consumption for Streamlit and Model pods
2. **Memory Usage** - Memory utilization tracking
3. **Network I/O** - Network traffic (RX/TX) for both services
4. **Pod Status** - Health status indicators

### How to Access the Dashboard

1. Log into Grafana at http://localhost:30200
2. Click on "Dashboards" (four squares icon) in the left sidebar
3. Search for "House Price Predictor"
4. Click on the dashboard to view real-time metrics

## 🔍 Explore Other Dashboards

Grafana comes pre-configured with many Kubernetes dashboards:
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Node (Pods)
- Kubernetes / Networking / Cluster
- And many more!

## 📈 Adding Custom Application Metrics (Optional)

To add custom metrics from your applications:

### For the FastAPI Model Service

1. Install prometheus-client:
   ```bash
   pip install prometheus-client
   ```

2. Add to your FastAPI app:
   ```python
   from prometheus_client import Counter, Histogram, generate_latest
   from fastapi import Response

   # Define metrics
   prediction_counter = Counter('predictions_total', 'Total number of predictions')
   prediction_duration = Histogram('prediction_duration_seconds', 'Prediction duration')

   @app.get("/metrics")
   async def metrics():
       return Response(content=generate_latest(), media_type="text/plain")

   @app.post("/predict")
   async def predict(data: dict):
       with prediction_duration.time():
           # Your prediction logic
           result = make_prediction(data)
           prediction_counter.inc()
           return result
   ```

3. Create a ServiceMonitor:
   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: model-metrics
     namespace: default
   spec:
     selector:
       matchLabels:
         app: model
     endpoints:
     - port: http
       path: /metrics
   ```

### For Streamlit

Streamlit doesn't have built-in Prometheus support, but you can:
- Use a sidecar container to expose metrics
- Or use the existing Kubernetes metrics (CPU, memory, network)

## 🔧 Prometheus Query Examples

You can create custom panels with these queries:

### CPU Usage
```promql
rate(container_cpu_usage_seconds_total{namespace="default",pod=~"streamlit-.*"}[5m])
```

### Memory Usage
```promql
container_memory_usage_bytes{namespace="default",pod=~"model-.*"}
```

### Pod Restart Count
```promql
kube_pod_container_status_restarts_total{namespace="default"}
```

### Network Traffic
```promql
rate(container_network_receive_bytes_total{namespace="default"}[5m])
```

## 🎨 Creating Custom Dashboards

1. Click the "+" icon in the left sidebar
2. Select "Dashboard"
3. Click "Add new panel"
4. Enter your Prometheus query
5. Configure visualization settings
6. Click "Apply" and "Save dashboard"

## 🔔 Setting Up Alerts (Optional)

1. Go to "Alerting" → "Alert rules"
2. Click "New alert rule"
3. Set conditions (e.g., CPU > 80%)
4. Configure notification channels
5. Save the alert rule

## 📚 Useful Resources

- Grafana Docs: https://grafana.com/docs/
- PromQL Guide: https://prometheus.io/docs/prometheus/latest/querying/basics/
- Kubernetes Monitoring Guide: https://prometheus.io/docs/guides/kubernetes-monitoring/
