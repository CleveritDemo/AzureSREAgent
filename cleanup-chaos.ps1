# Script de Limpieza para Saturación Agresiva
# Ejecutar: .\cleanup-chaos.ps1

Write-Host "🧹🧹🧹 LIMPIEZA DE CAOS INICIADA 🧹🧹🧹" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan

# Función para ejecutar comando con manejo de errores
function Invoke-KubectlCommand {
    param([string]$Command, [string]$Description)
    
    Write-Host "🔄 $Description..." -ForegroundColor Yellow
    try {
        Invoke-Expression $Command
        Write-Host "   ✅ Completado" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️ Error o recurso no encontrado: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 1. Eliminar Deployments
Write-Host "📦 PASO 1: Eliminando Deployments..." -ForegroundColor Cyan
$deployments = @(
    "cpu-gradual-killer",
    "cpu-destroyer-aggressive", 
    "cpu-bomb-1", "cpu-bomb-2", "cpu-bomb-3", "cpu-bomb-4", "cpu-bomb-5",
    "cpu-mem-double-bomb"
)

foreach ($deployment in $deployments) {
    Invoke-KubectlCommand "kubectl delete deployment $deployment --ignore-not-found=true --timeout=30s" "Eliminando deployment $deployment"
}

# 2. Eliminar DaemonSet
Write-Host "🔧 PASO 2: Eliminando DaemonSets..." -ForegroundColor Cyan
Invoke-KubectlCommand "kubectl delete daemonset per-node-cpu-killer --ignore-not-found=true --timeout=30s" "Eliminando DaemonSet per-node-cpu-killer"

# 3. Eliminar Jobs
Write-Host "⚙️ PASO 3: Eliminando Jobs..." -ForegroundColor Cyan
Invoke-KubectlCommand "kubectl delete job massive-cpu-job --ignore-not-found=true --timeout=30s" "Eliminando Job massive-cpu-job"

# 4. Eliminar Pods individuales
Write-Host "🚀 PASO 4: Eliminando pods nucleares individuales..." -ForegroundColor Cyan
for ($i = 1; $i -le 50; $i++) {
    Invoke-KubectlCommand "kubectl delete pod nuke-pod-$i --ignore-not-found=true --force --grace-period=0" "Eliminando nuke-pod-$i"
    
    if ($i % 10 -eq 0) {
        Write-Host "   📊 Eliminados $i pods nucleares..." -ForegroundColor Gray
    }
}

# 5. Limpiar pods fallidos
Write-Host "🗑️ PASO 5: Limpiando pods fallidos..." -ForegroundColor Cyan
Invoke-KubectlCommand "kubectl delete pods --field-selector=status.phase=Failed --force --grace-period=0" "Eliminando pods fallidos"

# 6. Limpiar pods pendientes problemáticos
Write-Host "⏳ PASO 6: Limpiando pods pendientes problemáticos..." -ForegroundColor Cyan
Invoke-KubectlCommand "kubectl delete pods --field-selector=status.phase=Pending --force --grace-period=0" "Eliminando pods pendientes"

# 7. Verificar limpieza
Write-Host "🔍 PASO 7: Verificando limpieza..." -ForegroundColor Cyan
Start-Sleep 5

try {
    $remainingPods = kubectl get pods --no-headers 2>$null | Where-Object { 
        $_ -match "cpu-" -or $_ -match "nuke-pod" -or $_ -match "double-bomb" -or $_ -match "node-killer"
    }
    
    if ($remainingPods) {
        Write-Host "⚠️ Pods restantes encontrados:" -ForegroundColor Yellow
        $remainingPods | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
        
        Write-Host "🔧 Intentando eliminación forzada..." -ForegroundColor Yellow
        $remainingPods | ForEach-Object {
            $podName = ($_ -split '\s+')[0]
            kubectl delete pod $podName --force --grace-period=0 2>$null
        }
    }
    else {
        Write-Host "✅ ¡Limpieza completa! No se encontraron pods de caos restantes." -ForegroundColor Green
    }
    
    # Mostrar estado actual del cluster
    Write-Host ""
    Write-Host "📊 ESTADO ACTUAL DEL CLUSTER:" -ForegroundColor Cyan
    kubectl top nodes 2>$null
    
    Write-Host ""
    $totalPods = (kubectl get pods --no-headers 2>$null).Count
    Write-Host "🚀 Total de pods activos: $totalPods" -ForegroundColor Green
    
}
catch {
    Write-Host "⚠️ Error verificando el estado final: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉🎉🎉 LIMPIEZA COMPLETADA 🎉🎉🎉" -ForegroundColor Green
Write-Host "El cluster debería volver a la normalidad en unos minutos." -ForegroundColor Cyan
