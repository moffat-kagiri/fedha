# Setup Cloudflare Tunnel for Fedha Backend
# This script helps set up and manage a Cloudflare tunnel connection

# Check if cloudflared is installed
$cloudflared = "$env:TEMP\cloudflared.exe"
if (-not (Test-Path $cloudflared)) {
    Write-Host "Downloading Cloudflare Tunnel client..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cloudflared
    Write-Host "Cloudflare Tunnel client downloaded to $cloudflared"
}

# Get the current directory
$currentDir = Get-Location

# Create the config directory if it doesn't exist
$configDir = "$currentDir\cloudflare_config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir | Out-Null
    Write-Host "Created config directory at $configDir"
}

# Function to create and start a quick tunnel
function Start-QuickTunnel {
    param(
        [string]$serverUrl = "http://localhost:8000"
    )
    
    Write-Host "Starting a quick tunnel to $serverUrl"
    Write-Host "Press Ctrl+C to stop the tunnel"
    
    # Start the tunnel
    & $cloudflared tunnel --url $serverUrl
}

# Function to update the API config with tunnel URL
function Update-ApiConfig {
    param(
        [string]$tunnelUrl
    )
    
    $apiConfigPath = "$currentDir\..\app\lib\config\api_config.dart"
    
    if (Test-Path $apiConfigPath) {
        $content = Get-Content -Path $apiConfigPath -Raw
        
        # Check if the file contains the development factory method
        if ($content -match "factory ApiConfig\.development\(\)") {
            # Replace the URL in the development configuration
            $pattern = '(primaryApiUrl:\s*[''"])[^''"]+([''"]),?'
            $replacement = "`$1$tunnelUrl`$2"
            $content = $content -replace $pattern, $replacement
            
            # Save the modified content
            Set-Content -Path $apiConfigPath -Value $content
            
            Write-Host "Updated API config to use tunnel URL: $tunnelUrl"
        } else {
            Write-Host "Could not find development configuration in API config file"
        }
    } else {
        Write-Host "API config file not found at $apiConfigPath"
    }
}

# Function to create a test file for the tunnel
function Create-TunnelTest {
    param(
        [string]$tunnelUrl
    )
    
    $testFilePath = "$currentDir\..\app\test_cloudflare_tunnel.dart"
    
    $testContent = @"
// Cloudflare Tunnel Test for Fedha App
// This file tests the connection to the Cloudflare tunnel

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CloudflareTunnelTestApp());
}

class CloudflareTunnelTestApp extends StatelessWidget {
  const CloudflareTunnelTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloudflare Tunnel Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TunnelTestScreen(),
    );
  }
}

class TunnelTestScreen extends StatefulWidget {
  const TunnelTestScreen({Key? key}) : super(key: key);

  @override
  _TunnelTestScreenState createState() => _TunnelTestScreenState();
}

class _TunnelTestScreenState extends State<TunnelTestScreen> {
  String _status = 'Testing connection...';
  String _response = '';
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection to Cloudflare tunnel...';
    });

    try {
      // Try to connect to the health endpoint
      final tunnelUrl = '$tunnelUrl';
      final healthEndpoint = 'https://$tunnelUrl/api/health/';
      
      setState(() {
        _status = 'Connecting to: $healthEndpoint';
      });
      
      final response = await http.get(Uri.parse(healthEndpoint))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isConnected = true;
          _status = 'Connection successful!';
          _response = const JsonEncoder.withIndent('  ').convert(data);
        });
      } else {
        setState(() {
          _isConnected = false;
          _status = 'Connection failed with status: $${response.statusCode}';
          _response = response.body;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _status = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudflare Tunnel Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: _isConnected ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected 
                              ? 'Connected to Cloudflare Tunnel' 
                              : 'Failed to connect to Cloudflare Tunnel',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_response.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Server Response:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(_response),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('Test Connection Again'),
            ),
          ],
        ),
      ),
    );
  }
}
"@
    
    Set-Content -Path $testFilePath -Value $testContent
    
    Write-Host "Created tunnel test file at $testFilePath"
    Write-Host "Run it with: flutter run -d chrome test_cloudflare_tunnel.dart"
}

# Main menu
function Show-Menu {
    Clear-Host
    Write-Host "================ Fedha Cloudflare Tunnel Setup ================"
    Write-Host "1: Start a quick tunnel to local server (http://localhost:8000)"
    Write-Host "2: Start a quick tunnel to network server (http://192.168.100.6:8000)"
    Write-Host "3: Update API config with tunnel URL"
    Write-Host "4: Create tunnel test file"
    Write-Host "Q: Quit"
    Write-Host "=============================================================="
}

# Main execution
$choice = ""
while ($choice -ne "Q") {
    Show-Menu
    $choice = Read-Host "Please select an option"
    
    switch ($choice) {
        "1" {
            Start-QuickTunnel -serverUrl "http://localhost:8000"
        }
        "2" {
            Start-QuickTunnel -serverUrl "http://192.168.100.6:8000" 
        }
        "3" {
            $tunnelUrl = Read-Host "Enter the Cloudflare tunnel URL (e.g., abcd-123-xyz.trycloudflare.com)"
            Update-ApiConfig -tunnelUrl $tunnelUrl
        }
        "4" {
            $tunnelUrl = Read-Host "Enter the Cloudflare tunnel URL (e.g., abcd-123-xyz.trycloudflare.com)"
            Create-TunnelTest -tunnelUrl $tunnelUrl
        }
        "Q" {
            Write-Host "Exiting..."
        }
        default {
            Write-Host "Invalid option. Please try again."
        }
    }
    
    if ($choice -ne "Q" -and $choice -ne "1" -and $choice -ne "2") {
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
