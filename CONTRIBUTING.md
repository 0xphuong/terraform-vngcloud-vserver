# Contributing

## Development Setup

```bash
brew install terraform tflint terraform-docs
git clone https://github.com/binhphuongit/terraform-vngcloud-vserver.git
cd terraform-vngcloud-vserver
```

## Making Changes

1. Create a branch: `git checkout -b feature/your-feature`
2. Make changes
3. Run checks locally:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
tflint --recursive
```

4. Update `CHANGELOG.md` under `[Unreleased]`
5. Open a Pull Request against `main`

## Security Note

Never commit secrets in `cloud-config.tpl` or any `.tf` file.
Always use variables and pass sensitive values via `terraform.tfvars` (gitignored) or environment variables:

```bash
export TF_VAR_admin_password="your-password"
```

## Release Process

1. Update `CHANGELOG.md` — move `[Unreleased]` to the new version section
2. Merge PR to `main`
3. Tag: `git tag v1.1.0 && git push origin v1.1.0`
