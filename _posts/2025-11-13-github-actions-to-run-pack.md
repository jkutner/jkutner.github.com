---
layout: post
title:  "Using Github Actions to Run Buildpacks"
date:   2025-11-13 16:39:00
---

In my [previous post](https://jkutner.github.io/2025/09/24/inline-buildpacks.html), I showed you how to create an inline buildpack that live directly in your application repository. We created a Python buildpack that bundles `uv` for dependency installation, eliminating the need to maintain a separate buildpack repository.

But there's one more piece to make this workflow truly powerful: continuous integration. Let's set up Github Actions to automatically build and publish a Docker image every time you push code.

## Setting Up the GitHub Action

Create a file at `.github/workflows/build.yml` in your repository with the following contents:

{% raw %}
```yaml
name: Build with Pack

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Pack CLI
        uses: buildpacks/github-actions/setup-pack@v5.9.6

      - name: Log in to GitHub Container Registry
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build with Pack
        run: pack build --publish ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:latest -t ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:${{ github.sha }}
```
{% endraw %}

## Breaking Down the Workflow

Let's walk through what each part does:

### Triggers

```yaml
on:
  push:
    branches:
      - main
  pull_request:
```

The workflow runs on every push to `main` and on pull requests. This means PRs get a test build, but only main branch pushes result in published images.

### Permissions

```yaml
permissions:
  contents: read
  packages: write
```

GitHub Actions needs explicit permission to write to GitHub Packages. The `contents: read` permission allows checking out your code, while `packages: write` enables pushing to ghcr.io.

### Setup Steps

The workflow starts by checking out your code and installing the Pack CLI:

```yaml
- name: Checkout code
  uses: actions/checkout@v4

- name: Setup Pack CLI
  uses: buildpacks/github-actions/setup-pack@v5.9.6
```

The Pack CLI is what actually executes the buildpack. The official GitHub Action makes installation simple.

### Building and Publishing the Image

First, we authenticate to GitHub Container Registry using the built-in `GITHUB_TOKEN`:

{% raw %}
```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

Then run `pack` to build our application image:

{% raw %}
```yaml
- name: Build with Pack
  run: pack build --publish ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:latest -t ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:${{ github.sha }}
```
{% endraw %}

This is the same command you'd run locally, but with the `--publish` flag. It builds your application using the inline buildpack in your repository with the Heroku builder, and then writes the resulting image directly to the container registry. We create two tags: `latest` for convenience and the commit SHA for precise version tracking.

## Making Your Images Public

By default, packages on GitHub Container Registry are private. To make your image publicly accessible:

1. Go to your repository on GitHub
2. Click the "Packages" link on the right sidebar
3. Click on your package name
4. Click "Package settings" in the sidebar
5. Scroll down to "Danger Zone" and click "Change visibility"
6. Select "Public"

You can also link the package back to your repository from the package settings page.

## Using Your Published Images

Once the workflow runs, you can pull your image from anywhere:

```bash
docker pull ghcr.io/yourusername/python-inline-buildpack:latest
```

Or use a specific version:

```bash
docker pull ghcr.io/yourusername/python-inline-buildpack:abc123def
```

This is perfect for deploying to Kubernetes, cloud platforms, or anywhere else that accepts container images. 

If you see the following error, it means that you're running on a different CPU architecture than Github:

```
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
ERROR: failed to launch: determine start command: when there is no default process a command is required
```

I'll discuss how to solve this problem in a future post.

## The Big Picture

With inline buildpacks and GitHub Actions, you have a complete CI/CD pipeline that:

- Keeps your buildpack logic with your application code
- Automatically builds on every commit
- Publishes versioned, reproducible container images
- Requires no separate infrastructure or buildpack repositories

You can iterate on your buildpack, test changes in pull requests, and automatically deploy when merging to main. 

From here, you might want to:

- Set up deployment workflows that use your published images
- Create release tags that trigger special versioned builds
- Add build caching to speed up your CI runs

The inline buildpack pattern combined with GitHub Actions gives you a powerful foundation for building and shipping applications with custom build logic, all from a single repository.