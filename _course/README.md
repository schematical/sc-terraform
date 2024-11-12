This is NOT a full Terraform course, just how it applies to AWS.


```bash
aws iam get-users
```

When to use CLI vs Terraform

ECS Kill task example

Terraform spin up, forget to spin down.

## IAM User:

```bash
aws iam list-users
aws iam list-access-keys --user-name joe

aws iam list-policies --only-attached

aws iam list-user-policies --user-name joe
aws iam list-attached-user-policies --user-name joe

```

### IAM Groups:

```bash
aws iam list-groups

aws iam list-group-policies --group-name developers
aws iam list-attached-group-policies --group-name developers
```
## IAM Roles:
```bash
aws iam list-roles
aws iam list-attached-role-policies --role-name worker_role

```