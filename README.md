# terraform-aws-billing-notify-slack

Environment
- Python 3.7.0

![system1](https://user-images.githubusercontent.com/35726568/148738879-3e97f2da-a228-4160-8637-3723377eb91c.png)

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