# Local Dev Environment.

- We recommend using codespaces. We use it exclusively for all of our work.

## AWS Cleanup

- Givent that AWS accounts are harder to recreate we recommend using a tool called [aws-nuke](https://github.com/rebuy-de/aws-nuke) to quickly destroy all the resources in your AWS account. Here is an example of our configuration we use:

```yaml
regions:
  - us-west-2
  - global

account-blocklist:
  - "1111111111111" # root account

accounts:
  22222222222222:
    presets:
      - common

presets:
  common:
    filters:
      IAMRole:
        - type: regex
          value: ".*OrganizationAccountAccessRole.*"
      IAMRolePolicyAttachment:
        - type: regex
          value: ".*OrganizationAccountAccessRole.*"
      OpsWorksUserProfile:
        - type: regex
          value: ".*OrganizationAccountAccessRole.*"
```

**NOTE: replace `22222222222222` with the account ID you are trying to delete resources in. Be sure to update the whitelist to not remove the user you created earlier four yourself. Change `1111111111111` to be the actual account id of your root/prod account.**

## GCP cleanup

- Just shutdown/delete the project AND disable billing for the project. If you don't disable billing then it's likely you will still have resources running until the project is fully shutdown/deleted which can take up to 30 days.
