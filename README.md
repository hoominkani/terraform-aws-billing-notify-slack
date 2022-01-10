# terraform-aws-billing-notify-slack

You can simply use:

- Set slack webhook url 

main.tf
```
variable "webhook_url" {
    # your webhook url
    default = ""
}
```

```bash
$ git@github.com:hoominkani/terraform-aws-billing-notify-slack.git
$ sh lambda/deploy_sh
$ terrafrom plan
$ terrafrom apply
```