# Script PowerShell - SATURACIÓN AGRESIVA DE CPU (CORREGIDO)
# Ejecutar: .\AggressiveSaturation-FIXED.ps1

Write-Host "🚨🚨🚨 ATAQUE NUCLEAR AL CLUSTER 🚨🚨🚨" -ForegroundColor Red
Write-Host "⚠️  ADVERTENCIA: ESTO VA A SATURAR COMPLETAMENTE TU CLUSTER ⚠️" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan

$confirm = Read-Host "¿Estás SEGURO de que quieres continuar? (escribir 'DESTRUIR' para confirmar)"
if ($confirm -ne "DESTRUIR") {
    Write-Host "❌ Operación cancelada" -ForegroundColor Green
    exit
}

Write-Host "💀 INICIANDO DESTRUCCIÓN MASIVA..." -ForegroundColor Red
Start-Sleep 2

# 1. ESCALAR DEPLOYMENT EXISTENTE AL MÁXIMO
Write-Host "🚀 PASO 1: Escalando deployment existente a 50 réplicas..." -ForegroundColor Yellow
kubectl scale deployment cpu-gradual-killer --replicas=50 2>$null

# 2. DEPLOYMENT AGRESIVO
Write-Host "💣 PASO 2: Creando deployment agresivo..." -ForegroundColor Yellow
$aggressiveYaml = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-destroyer-aggressive
  namespace: default
spec:
  replicas: 25
  selector:
    matchLabels:
      app: cpu-destroyer
  template:
    metadata:
      labels:
        app: cpu-destroyer
    spec:
      containers:
      - name: destroyer
        image: alpine:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do yes > /dev/null & yes > /dev/null & yes > /dev/null & yes > /dev/null & dd if=/dev/zero of=/dev/null & dd if=/dev/zero of=/dev/null & wait; done"]
        resources:
          requests:
            cpu: "500m"
            memory: "100Mi"
          limits:
            cpu: "2000m"
            memory: "200Mi"
'@

$aggressiveYaml | kubectl apply -f - 2>$null

# 3. DAEMONSET PARA CADA NODO
Write-Host "⚡ PASO 3: Creando DaemonSet para saturar cada nodo..." -ForegroundColor Yellow
$daemonsetYaml = @'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: per-node-cpu-killer
  namespace: default
spec:
  selector:
    matchLabels:
      app: node-killer
  template:
    metadata:
      labels:
        app: node-killer
    spec:
      containers:
      - name: node-destroyer
        image: alpine:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do for i in $(seq 1 8); do yes > /dev/null & dd if=/dev/zero of=/dev/null & done; wait; done"]
        resources:
          requests:
            cpu: "1000m"
            memory: "100Mi"
          limits:
            cpu: "4000m"
            memory: "500Mi"
      tolerations:
      - operator: "Exists"
'@

$daemonsetYaml | kubectl apply -f - 2>$null

# 4. MÚLTIPLES DEPLOYMENTS SIMULTÁNEOS
Write-Host "🔥 PASO 4: Creando 5 deployments bomba simultáneos..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    $multiYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-bomb-$i
  namespace: default
spec:
  replicas: 15
  selector:
    matchLabels:
      app: cpu-bomb-$i
  template:
    metadata:
      labels:
        app: cpu-bomb-$i
    spec:
      containers:
      - name: bomber
        image: alpine:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do yes > /dev/null & yes > /dev/null & yes > /dev/null & wait; done"]
        resources:
          requests:
            cpu: "300m"
            memory: "50Mi"
          limits:
            cpu: "1500m"
            memory: "150Mi"
"@
    
    $multiYaml | kubectl apply -f - 2>$null
    Write-Host "    💥 Desplegado cpu-bomb-$i" -ForegroundColor Red
    Start-Sleep 1
}

# 5. JOB MASIVO
Write-Host "☢️  PASO 5: Lanzando job masivo con 30 workers paralelos..." -ForegroundColor Yellow
$jobYaml = @'
apiVersion: batch/v1
kind: Job
metadata:
  name: massive-cpu-job
  namespace: default
spec:
  parallelism: 30
  completions: 100
  template:
    spec:
      containers:
      - name: worker
        image: alpine:latest
        command: ["/bin/sh"]
        args: ["-c", "timeout 300 sh -c 'while true; do yes > /dev/null & yes > /dev/null & yes > /dev/null & wait; done'"]
        resources:
          requests:
            cpu: "400m"
            memory: "50Mi"
          limits:
            cpu: "2000m"
            memory: "200Mi"
      restartPolicy: OnFailure
'@

$jobYaml | kubectl apply -f - 2>$null

# 6. BOMBA NUCLEAR - PODS INDIVIDUALES
Write-Host "☢️  PASO 6: BOMBA NUCLEAR - Creando 50 pods individuales..." -ForegroundColor Red
for ($j = 1; $j -le 50; $j++) {
    $podName = "nuke-pod-$j"
    kubectl run $podName --image=alpine:latest --restart=Never --requests='cpu=50m,memory=50Mi' --limits='cpu=1500m,memory=200Mi' -- sh -c 'while true; do yes > /dev/null & yes > /dev/null & yes > /dev/null & yes > /dev/null & wait; done' 2>$null
    
    if ($j % 10 -eq 0) {
        Write-Host "    🚀 Creados $j pods nucleares..." -ForegroundColor Red
    }
    Start-Sleep 0.2
}

# 7. BOMBA DE CPU + MEMORIA (Simplificada)
Write-Host "💀 PASO 7: Bomba combinada CPU + MEMORIA..." -ForegroundColor Yellow
$doubleBombYaml = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-mem-double-bomb
  namespace: default
spec:
  replicas: 10
  selector:
    matchLabels:
      app: double-bomb
  template:
    metadata:
      labels:
        app: double-bomb
    spec:
      containers:
      - name: cpu-killer
        image: alpine:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do yes > /dev/null & yes > /dev/null & yes > /dev/null & yes > /dev/null & wait; done"]
        resources:
          requests:
            cpu: "1000m"
            memory: "500Mi"
          limits:
            cpu: "3000m"
            memory: "1Gi"
      - name: mem-killer
        image: alpine:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do dd if=/dev/zero of=/tmp/memfill bs=1M count=512 2>/dev/null; sleep 1; done"]
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "2000m"
            memory: "1Gi"
'@

$doubleBombYaml | kubectl apply -f - 2>$null

Write-Host ""
Write-Host "💀💀💀 CAOS TOTAL DESPLEGADO 💀💀💀" -ForegroundColor Red
Write-Host "====================================" -ForegroundColor Red

# MONITOREO EN TIEMPO REAL
Write-Host "🔍 Iniciando monitoreo en tiempo real..." -ForegroundColor Cyan
Write-Host "Presiona Ctrl+C para detener el monitoreo" -ForegroundColor Gray

$monitorCount = 0
try {
    while ($true) {
        Clear-Host
        $monitorCount++
        
        Write-Host "💀💀💀 DESTRUCCIÓN MASIVA EN PROGRESO 💀💀💀" -ForegroundColor Red
        Write-Host "Monitoreo #$monitorCount" -ForegroundColor Gray
        Write-Host "=============================================" -ForegroundColor Red
        
        try {
            kubectl top nodes 2>$null
            Write-Host ""
            
            $allPods = kubectl get pods --no-headers 2>$null
            if ($allPods) {
                $totalPods = ($allPods | Where-Object { $_ -match "Running" }).Count
                $pendingPods = ($allPods | Where-Object { $_ -match "Pending" }).Count
                $failedPods = ($allPods | Where-Object { $_ -match "Failed" }).Count
                
                Write-Host "🚀 Pods corriendo: $totalPods" -ForegroundColor Green
                Write-Host "⏳ Pods pendientes: $pendingPods" -ForegroundColor Yellow
                Write-Host "❌ Pods fallidos: $failedPods" -ForegroundColor Red
                Write-Host "💣 TOTAL CAOS: $($totalPods + $pendingPods + $failedPods)" -ForegroundColor Red
                
                # Verificar si llegamos al objetivo
                $nodeOutput = kubectl top nodes --no-headers 2>$null
                if ($nodeOutput) {
                    $maxCpu = 0
                    $nodeOutput | ForEach-Object {
                        if ($_ -match '(\d+)%') {
                            $cpu = [int]$matches[1]
                            if ($cpu -gt $maxCpu) { $maxCpu = $cpu }
                        }
                    }
                    
                    if ($maxCpu -ge 95) {
                        Write-Host ""
                        Write-Host "🎯🎯🎯 OBJETIVO ALCANZADO! CPU MÁXIMO: $maxCpu% 🎯🎯🎯" -ForegroundColor Green
                        Write-Host "💀 CLUSTER COMPLETAMENTE SATURADO 💀" -ForegroundColor Red
                    }
                }
            }
        }
        catch {
            Write-Host "⚠️ Error obteniendo métricas - Cluster posiblemente saturado" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "🧹 Para limpiar después ejecuta: .\cleanup-chaos.ps1" -ForegroundColor Cyan
        Start-Sleep 3
    }
}
catch {
    Write-Host "🛑 Monitoreo interrumpido" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🧹 COMANDOS DE LIMPIEZA:" -ForegroundColor Cyan
Write-Host "kubectl delete deployment cpu-gradual-killer cpu-destroyer-aggressive cpu-bomb-1 cpu-bomb-2 cpu-bomb-3 cpu-bomb-4 cpu-bomb-5 cpu-mem-double-bomb --ignore-not-found=true" -ForegroundColor White
Write-Host "kubectl delete daemonset per-node-cpu-killer --ignore-not-found=true" -ForegroundColor White
Write-Host "kubectl delete job massive-cpu-job --ignore-not-found=true" -ForegroundColor White
Write-Host "kubectl delete pods --selector=app=nuke --force --grace-period=0" -ForegroundColor White
Write-Host "kubectl delete pods --field-selector=status.phase=Failed --force --grace-period=0" -ForegroundColor White
