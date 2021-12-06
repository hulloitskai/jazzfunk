# jazzfunk

_The configuration and state of my personal computing cluster, `jazzfunk`._

### Directories:

- [`infra`](./infra) – [Terraform](https://www.terraform.io) infrastructure
  configuration and state.
- [`cluster`](./cluster) – [Kubernetes](https://kubernetes.io) cluster configuration and state.

---

## Setup

1.  Configure environment variables (fill a `.env` with values, with a format
    matching `.env.example`).

2.  Load the `.env`:

    ```bash
    source .env
    ```

3.  Create the infrastructure with [Terraform](https://www.terraform.io):

    ```bash
    cd infra         # navigate to the infra directory
    terraform init   # ensure all plugins are installed
    terraform apply  # apply configuration
    ```

4.  Install Flux on-cluster:
    ```bash
    flux bootstrap github \
      --owner=hulloitskai \
      --repository=jazzfunk \
      --components-extra=image-reflector-controller,image-automation-controller \
      --read-write-key \
      --reconcile \
      --personal \
      --path=system \
      --interval=1m
    ```
