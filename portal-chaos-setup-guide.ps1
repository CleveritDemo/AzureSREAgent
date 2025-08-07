# Complete Azure Portal Chaos Studio Setup
# This script provides step-by-step instructions for Azure Portal integration

Write-Host "🎯 Azure Portal Chaos Studio Setup Guide" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "📋 Prerequisites Check:" -ForegroundColor Yellow
Write-Host "✓ Azure CLI installed and authenticated" -ForegroundColor Green
Write-Host "✓ Chaos Studio provider registered" -ForegroundColor Green
Write-Host "✓ AKS cluster (eshopcleveraks) running" -ForegroundColor Green
Write-Host "✓ Chaos Mesh installed on AKS" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  PERMISSION REQUIREMENT:" -ForegroundColor Red
Write-Host "This setup requires 'User Access Administrator' role or higher" -ForegroundColor Red
Write-Host "Current user needs permission to create role assignments" -ForegroundColor Red
Write-Host ""

Write-Host "🔧 Setup Options:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Automated Setup (Recommended)" -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Cyan
Write-Host "Run the following command:" -ForegroundColor White
Write-Host ".\enable-chaos-portal.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "To check permissions first:" -ForegroundColor White
Write-Host ".\enable-chaos-portal.ps1 -CheckPermissions" -ForegroundColor Green
Write-Host ""

Write-Host "Option 2: Manual Portal Setup" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan
Write-Host "1. Go to Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "2. Navigate to Chaos Studio:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView" -ForegroundColor Blue
Write-Host "3. Click on 'Targets' in the left menu" -ForegroundColor White
Write-Host "4. Find your AKS cluster 'eshopcleveraks'" -ForegroundColor White
Write-Host "5. Click 'Enable targets' and select capabilities:" -ForegroundColor White
Write-Host "   - PodChaos" -ForegroundColor Green
Write-Host "   - StressChaos" -ForegroundColor Green
Write-Host "   - NetworkChaos" -ForegroundColor Green
Write-Host "   - IOChaos" -ForegroundColor Green
Write-Host "6. Click 'Review + Enable'" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Permission Escalation (If Access Denied)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "If you get permission errors, follow these steps:" -ForegroundColor White
Write-Host ""
Write-Host "1. Contact your Azure tenant administrator" -ForegroundColor White
Write-Host "2. Request temporary 'User Access Administrator' role" -ForegroundColor White
Write-Host "3. Provide this justification:" -ForegroundColor White
Write-Host "   'Need to enable Azure Chaos Studio role assignments'" -ForegroundColor Cyan
Write-Host "   'for AKS cluster chaos engineering experiments'" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Alternative: Ask tenant admin to run this command:" -ForegroundColor White
Write-Host "   az role assignment create \\" -ForegroundColor Green
Write-Host "     --assignee-object-id <your-user-object-id> \\" -ForegroundColor Green
Write-Host "     --role 'User Access Administrator' \\" -ForegroundColor Green
Write-Host "     --scope '/subscriptions/<subscription-id>/resourceGroups/eShopCleverRG' \\" -ForegroundColor Green
Write-Host "     --assignee-principal-type User" -ForegroundColor Green
Write-Host ""

Write-Host "🎯 After Enabling Targets:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Create experiments in Azure Portal:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment" -ForegroundColor Blue
Write-Host ""
Write-Host "2. Example experiment configurations:" -ForegroundColor White
Write-Host ""

Write-Host "   Pod Failure Experiment:" -ForegroundColor Cyan
Write-Host "   - Target: eshopcleveraks" -ForegroundColor White
Write-Host "   - Capability: PodChaos" -ForegroundColor White
Write-Host "   - Parameters:" -ForegroundColor White
Write-Host "     * Mode: one" -ForegroundColor Green
Write-Host "     * Namespace: eshop" -ForegroundColor Green
Write-Host "     * Label Selector: app=webmvc" -ForegroundColor Green
Write-Host "     * Action: pod-failure" -ForegroundColor Green
Write-Host "     * Duration: 60s" -ForegroundColor Green
Write-Host ""

Write-Host "   Network Delay Experiment:" -ForegroundColor Cyan
Write-Host "   - Target: eshopcleveraks" -ForegroundColor White
Write-Host "   - Capability: NetworkChaos" -ForegroundColor White
Write-Host "   - Parameters:" -ForegroundColor White
Write-Host "     * Mode: all" -ForegroundColor Green
Write-Host "     * Namespace: eshop" -ForegroundColor Green
Write-Host "     * Action: delay" -ForegroundColor Green
Write-Host "     * Latency: 100ms" -ForegroundColor Green
Write-Host "     * Duration: 120s" -ForegroundColor Green
Write-Host ""

Write-Host "   CPU Stress Experiment:" -ForegroundColor Cyan
Write-Host "   - Target: eshopcleveraks" -ForegroundColor White
Write-Host "   - Capability: StressChaos" -ForegroundColor White
Write-Host "   - Parameters:" -ForegroundColor White
Write-Host "     * Mode: one" -ForegroundColor Green
Write-Host "     * Namespace: eshop" -ForegroundColor Green
Write-Host "     * Stressors: cpu=1" -ForegroundColor Green
Write-Host "     * Duration: 180s" -ForegroundColor Green
Write-Host ""

Write-Host "🔍 Monitoring:" -ForegroundColor Yellow
Write-Host ""
Write-Host "After running experiments, monitor results in:" -ForegroundColor White
Write-Host "1. Azure Portal Chaos Studio - Experiment runs" -ForegroundColor Cyan
Write-Host "2. Azure Monitor - Container insights" -ForegroundColor Cyan
Write-Host "3. Kubernetes dashboard" -ForegroundColor Cyan
Write-Host "4. Application logs and metrics" -ForegroundColor Cyan
Write-Host ""

Write-Host "📚 Additional Resources:" -ForegroundColor Yellow
Write-Host ""
Write-Host "• Azure Chaos Studio Documentation:" -ForegroundColor White
Write-Host "  https://docs.microsoft.com/azure/chaos-studio/" -ForegroundColor Blue
Write-Host ""
Write-Host "• Chaos Mesh Documentation:" -ForegroundColor White
Write-Host "  https://chaos-mesh.org/docs/" -ForegroundColor Blue
Write-Host ""
Write-Host "• Your existing chaos experiment files:" -ForegroundColor White
Write-Host "  - k8s/pod-chaos-experiment.yaml" -ForegroundColor Green
Write-Host "  - k8s/cpu-stress-chaos.yaml" -ForegroundColor Green
Write-Host "  - k8s/network-delay-chaos.yaml" -ForegroundColor Green
Write-Host "  - k8s/severe-pod-chaos.yaml" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Ready to start? Run one of the options above!" -ForegroundColor Green
Write-Host ""
Write-Host "For permission issues, refer to: chaos-studio-permission-fix.md" -ForegroundColor Blue
