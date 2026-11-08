# Ficsit-Codes Documentation

## Overview

Ficsit-Codes is a network boot system for virtual machines, designed to manage and deploy programs across multiple machines in a Satisfactory-like environment.

## System Architecture

The system consists of several components:

1. **Net-Boot Server** (`boot-server.lua`)
   - Loads programs and libraries from GitHub
   - Distributes programs to clients on request
   - Manages program versions and updates

2. **Net-Boot Client** (`boot-client.lua`)
   - Connects to the net-boot server
   - Retrieves and executes programs
   - Handles program updates and restarts

3. **Management Console** (`management-console.lua`)
   - Centralized management interface
   - Provides API for remote management
   - Monitors and controls net-boot servers

## Programs

### Core Programs

- **init.lua**: Initialization program that loads the boot client
- **boot-client.lua**: Main client program that connects to the net-boot server
- **remote-test.lua**: Test program for demonstration purposes
- **dban.lua**: Database management program
- **depot-mgmt.lua**: Depot management program
- **train-mgmt.lua**: Train management program
- **management-console.lua**: Centralized management console

## Libraries

### Utility Libraries

- **debug-print.lua**: Enhanced debug printing
- **mountLib.lua**: Filesystem mounting utilities
- **deepcopy.lua**: Deep copy implementation
- **tablelength.lua**: Get length of a table
- **getPercentage.lua**: Percentage calculation utilities
- **stationState.lua**: Station state management

### System Libraries

- **logging.lua**: Structured logging with multiple levels
- **error-handling.lua**: Error handling and retry mechanisms
- **dependency-mgmt.lua**: Dependency management and resolution
- **cache.lua**: Caching system for programs and libraries
- **update-mgmt.lua**: Update management and version tracking

## Configuration

### Net-Boot Server Configuration

The net-boot server can be configured with:
- `OS`: UUID of the operating system
- `netBootPort`: Port for net-boot communication
- `netBootPrograms`: Dictionary of available programs
- `netLibPrograms`: Dictionary of available libraries

### Client Configuration

Clients can be configured with:
- `netBootProgramName`: Name of the program to execute
- `netBootPort`: Port for net-boot communication

### Management Console Configuration

The management console uses:
- `MANAGEMENT_PORT`: Port for management API (default: 4200)
- `NET_BOOT_PORT`: Port for net-boot communication (default: 1)

## Usage

### Starting the Net-Boot Server

```lua
-- Run boot-server.lua on a machine with network access
-- The server will automatically load programs and libraries from GitHub
```

### Starting a Client

```lua
-- Run init.lua on a client machine
-- The client will connect to the net-boot server and load the configured program
```

### Using the Management Console

```lua
-- Run management-console.lua on a dedicated management machine
-- The console provides a network API for remote management
```

## Network Communication

### Ports

- **Port 1**: Net-Boot communication (server to client)
- **Port 4200**: Management console API

### Message Types

#### Net-Boot Messages

- `getEEPROM <programName>`: Request program code
- `setEEPROM <programName> <code>`: Send program code
- `getLibrary <libraryName>`: Request library code
- `setLibrary <libraryName> <code>`: Send library code
- `reset <programName>`: Reset a program
- `ping`: Health check
- `pong`: Health check response

#### Management Console Messages

- `register <port>`: Register a net-boot server
- `getProgramList`: Get list of available programs
- `getLibraryList`: Get list of available libraries
- `checkUpdates`: Check for available updates
- `applyUpdates <updates>`: Apply updates
- `getClientList`: Get list of connected clients
- `rebootClient <clientAddress>`: Reboot a client
- `updateConfig <clientAddress> <config>`: Update client configuration

## Error Handling

The system includes robust error handling:

- Retry mechanisms with exponential backoff
- Timeout handling for network operations
- Validation of Lua code syntax
- Checksum verification for downloaded files

## Logging

The logging system provides multiple levels:

- **DEBUG**: Detailed debug information
- **INFO**: Informational messages
- **WARN**: Warning messages
- **ERROR**: Error messages

Logging can be configured to output to console, files, or both.

## Updates

The system supports automatic updates:

- Version tracking for programs and libraries
- Update checking at configurable intervals
- Automatic application of updates
- Cache invalidation after updates

## Dependencies

The dependency management system:

- Tracks dependencies between programs
- Ensures proper execution order
- Manages program states
- Validates dependency satisfaction before execution

## Caching

The caching system:

- Stores downloaded programs and libraries
- Configurable cache size and age limits
- Automatic cache invalidation on updates
- Disk-based storage for persistence

## Best Practices

1. **Program Design**: Keep programs focused and modular
2. **Error Handling**: Always handle errors gracefully
3. **Logging**: Use appropriate log levels for different types of messages
4. **Updates**: Test updates before applying them to production systems
5. **Configuration**: Store sensitive configuration separately from code
6. **Security**: Validate all incoming data and use checksums for verification

## Troubleshooting

### Common Issues

1. **Connection Failures**: Check network connectivity and port configurations
2. **Program Failures**: Check logs for error messages
3. **Update Failures**: Verify network access to the update server
4. **Dependency Errors**: Ensure all dependencies are properly registered

### Debugging Tips

1. Enable DEBUG logging for detailed information
2. Check both server and client logs
3. Verify network connectivity between machines
4. Check program versions and update status

## Development

### Adding New Programs

1. Create a new Lua file in the `codes/` directory
2. Add the program name to `code.lst`
3. Register the program with the dependency management system
4. Test the program thoroughly

### Adding New Libraries

1. Create a new Lua file in the `libs/` directory
2. Add the library name to `lib.lst`
3. Test the library with existing programs

### Testing

- Test programs in isolation before integrating with the system
- Verify dependency relationships
- Test error handling and recovery scenarios
- Test update and rollback procedures

## Future Enhancements

1. **Security**: Add authentication and encryption for network communication
2. **Monitoring**: Implement comprehensive monitoring and alerting
3. **Scalability**: Support for multiple net-boot servers
4. **High Availability**: Failover and load balancing
5. **Web Interface**: Graphical management interface

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please follow the existing code style and add tests for new features.
