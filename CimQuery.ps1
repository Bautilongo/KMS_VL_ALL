param(
    [Parameter(Mandatory = $true)]
    [string]$ClassName,
    [string]$Filter,
    [string]$Property,
    [switch]$Value,
    [string]$Namespace = 'root\cimv2',
    [string]$MethodName,
    [string[]]$MethodArgument
)

$ErrorActionPreference = 'Stop'

try {
    if ($MethodName) {
        $arguments = @{}
        foreach ($argument in $MethodArgument) {
            $name, $value = $argument -split '=', 2
            if ($name -eq 'Force') {
                $arguments[$name] = $value -ieq 'true'
            } else {
                $arguments[$name] = $value
            }
        }

        if ($Namespace -eq 'root\Microsoft\Windows\Defender') {
            $results = Invoke-CimMethod -Namespace $Namespace -ClassName $ClassName -MethodName $MethodName -Arguments $arguments
        } else {
            $instances = if ($Filter) {
                Get-CimInstance -Namespace $Namespace -ClassName $ClassName -Filter $Filter
            } else {
                Get-CimInstance -Namespace $Namespace -ClassName $ClassName
            }
            $results = $instances | ForEach-Object {
                Invoke-CimMethod -InputObject $_ -MethodName $MethodName -Arguments $arguments
            }
        }

        if ($null -ne $results) {
            $result = @($results)[-1]
            if ($null -ne $result.ReturnValue) {
                $returnCode = [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$result.ReturnValue), 0)
                exit $returnCode
            }
        }
        exit 0
    }

    $instances = if ($Filter) {
        Get-CimInstance -Namespace $Namespace -ClassName $ClassName -Filter $Filter
    } else {
        Get-CimInstance -Namespace $Namespace -ClassName $ClassName
    }

    foreach ($instance in $instances) {
        $propertyValue = $instance.$Property
        if ($null -ne $propertyValue) {
            if ($Value) {
                '{0}={1}' -f $Property, $propertyValue
            } else {
                $propertyValue
            }
        }
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
