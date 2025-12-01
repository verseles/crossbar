# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in Crossbar, please report it responsibly.

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please report security issues by emailing:

**security@verseles.com**

Or use GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/verseles/crossbar/security) of the repository
2. Click "Report a vulnerability"
3. Fill out the form with details

### What to Include

Please include the following in your report:

- **Description**: A clear description of the vulnerability
- **Impact**: What an attacker could accomplish by exploiting it
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Affected Versions**: Which versions are affected
- **Possible Fix**: If you have suggestions for how to fix the issue
- **Your Contact**: How we can reach you for follow-up questions

### Response Timeline

- **Acknowledgment**: We will acknowledge receipt of your report within **48 hours**
- **Initial Assessment**: We will provide an initial assessment within **7 days**
- **Resolution**: We aim to resolve critical vulnerabilities within **30 days**
- **Disclosure**: We will coordinate disclosure timing with you

### What to Expect

1. **Confirmation**: We'll confirm we received your report
2. **Communication**: We'll keep you updated on our progress
3. **Credit**: With your permission, we'll credit you in the security advisory
4. **No Legal Action**: We will not pursue legal action against researchers who follow responsible disclosure

## Security Considerations

### Plugin Security

Crossbar executes plugins as scripts with the same permissions as the running user. This is a known design decision for flexibility, but users should be aware:

- **Only run trusted plugins**: Plugins can execute arbitrary code
- **Review third-party plugins**: Check the source code before installing
- **Be cautious with marketplace plugins**: Verify the author and reviews

### Secure Storage

Sensitive configuration values (type `password`) are stored using platform-specific secure storage:

| Platform | Storage Method |
|----------|---------------|
| Linux | libsecret (GNOME Keyring, KWallet) |
| macOS | Keychain |
| Windows | Credential Manager |

### Network Security

- All HTTP requests from plugins use HTTPS by default
- The IPC server only listens on `localhost:48291` (not accessible remotely)
- No data is sent to external servers by Crossbar itself

### File Permissions

- Plugin files should have restricted permissions (`chmod 700` or `750`)
- Configuration files may contain sensitive data (API keys)
- Crossbar respects file system permissions

## Known Limitations

The following are known security considerations, not vulnerabilities:

1. **No Plugin Sandboxing**: Plugins run with full user permissions
2. **No Plugin Signing**: Plugins are not cryptographically signed
3. **No Plugin Verification**: Marketplace plugins are not reviewed for security
4. **Local IPC Server**: The IPC server is accessible to local processes

These are documented trade-offs for the initial release. Future versions may address these through optional security enhancements.

## Security Best Practices for Users

1. **Keep Crossbar updated**: Install security updates promptly
2. **Review plugin source code**: Especially for third-party plugins
3. **Use secure API keys**: Don't share keys across services
4. **Limit plugin permissions**: If possible, run sensitive plugins with reduced privileges
5. **Monitor plugin behavior**: Check logs for unexpected activity

## Security Best Practices for Plugin Developers

1. **Validate all inputs**: Never trust user input or external data
2. **Use HTTPS**: Always use secure connections for network requests
3. **Don't hardcode secrets**: Use configuration files for API keys
4. **Handle errors gracefully**: Don't expose sensitive information in error messages
5. **Minimize dependencies**: Fewer dependencies = smaller attack surface
6. **Document security requirements**: Let users know what permissions your plugin needs

## Acknowledgments

We appreciate the security community's efforts in responsibly disclosing vulnerabilities. Contributors who report valid security issues will be acknowledged in our security advisories (with their permission).

---

## Contact

For security concerns: **security@verseles.com**

For general questions: [GitHub Discussions](https://github.com/verseles/crossbar/discussions)

For bug reports: [GitHub Issues](https://github.com/verseles/crossbar/issues)
