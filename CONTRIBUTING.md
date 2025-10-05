# Contributing to Live EPL

Thank you for your interest in contributing to Live EPL! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/Football-analyser.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear messages: `git commit -m "Add: feature description"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Setup

See the [README.md](README.md) for detailed setup instructions.

### Local Development

```bash
# Start backend services
cd infra
docker-compose up -d

# Setup frontend
cd frontend/nextjs-app
npm install
npm run dev
```

## Code Style

### Python
- Follow PEP 8 style guide
- Use type hints where possible
- Add docstrings to functions and classes
- Keep functions focused and small

### TypeScript/JavaScript
- Use ESLint and Prettier
- Follow React best practices
- Use TypeScript for type safety
- Prefer functional components and hooks

### Commit Messages
- Use conventional commits format:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation
  - `refactor:` for code refactoring
  - `test:` for adding tests
  - `chore:` for maintenance tasks

## Pull Request Process

1. Update the README.md with details of changes if needed
2. Update documentation for any changed functionality
3. Add tests for new features
4. Ensure all tests pass
5. Update the CHANGELOG.md (if applicable)
6. Request review from maintainers

## Testing

### Backend
```bash
# Test producer
curl http://localhost:8000/health

# Test consumer
docker logs epl-consumer
```

### Frontend
```bash
cd frontend/nextjs-app
npm test
npm run build  # Ensure build succeeds
```

## Reporting Bugs

When reporting bugs, please include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- System information (OS, Docker version, etc.)
- Relevant logs or error messages

## Feature Requests

We welcome feature requests! Please:

- Check if the feature already exists
- Provide clear use cases
- Explain how it aligns with project goals
- Be open to discussion and iteration

## Code Review

All submissions require review. We use GitHub pull requests for this purpose.

### Review Criteria

- Code quality and readability
- Test coverage
- Documentation
- Performance implications
- Security considerations

## Community

- Be respectful and inclusive
- Help others learn and grow
- Share knowledge and best practices
- Provide constructive feedback

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Reach out to maintainers

Thank you for contributing! ⚽
