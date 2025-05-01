# WAFRN OCI OpenTofu scripts

Oracle Resource Manager compatible terraform / opentofu scripts to deploy a small but production-ready WAFRN instance to Oracle Cloud Infrastructure using only Always Free tier eligible instances

## Magic deploy quick install guide

[![Deploy to Oracle Cloud][magic_button]][magic_wafrn_basic_stack]

Requirements:

1. A domain name you control
2. Around 15 minutes

Steps to install:

1. Register for a new account on [Oracle Cloud](https://signup.cloud.oracle.com/)
2. Login and then press the Magic deploy button above
3. Fill in the details
4. Make sure to click "Apply" at the end
5. Wait until installation is finished
6. Update your domain DNS settings based on the instructions
7. Wait a bit more
8. PROFIT!

You can also deploy this repository manually by setting up the `.tfvars` by hand then running the directory throgh `tofu apply` or `terraform apply`

## Install guide

### Registration

You can [register for Oracle Cloud here](https://signup.cloud.oracle.com/). Email might be slow to arrive. Please note you need to enter your real legal name and address during signup as it will be verified against the credit card / debit card details. Entering fake details will likely fail verification.

When it comes to the Home Region selector make sure you select a region that you're happy that your data will reside in. It might also have some legal implications, for example selecting regions in the EU will definitely require you to abide to GDPR regulations, as well as any local regulations in that specific country.

There are some other considerations to look for, for example the server's location is used to generate link previews, so any resource that the server cannot access to will lack previews for everyone. For example if you select a location in Germany as your Home Region the server will not be able to access any YouTube videos that are blocked in Germany.

Also there might be warnings about low resources in some regions. It is advised to avoid them unless necessary.

![Home Region](images/home_region.png)

### Stack init

Click the below magic button to initiate your wafrn stack:

[![Deploy to Oracle Cloud][magic_button]][magic_wafrn_basic_stack]

Accept the terms and conditions

![Terms and Conditions](images/terms_and_conditions.png)

Then click NEXT on the bottom of the page

Next page is where you need to fill in your configuration. The following are the only mandatory details you need to fill in:

* WAFRN Domain name
* Administrator email address
* Administrator username
* Enable/Disable Bluesky integration
* Bluesky domain name and admin user's handle

You can also check "Show advanced options?" to enable/disable extra features. Please check the [Features section](#features) for mode details on these options. While the defaults are good as a basic setup you might want to go through the rest as well.

Once you finish click NEXT on the bottom of the page again.

On the final page double check that everything still makes sense. If yes, at the bottom of the page make sure "Run Apply" is selected, then click "CREATE"

![Apply button](images/apply.png)

(Forgot to enable "Run Apply"? You can click Apply separately on the next page)

Wait for Apply to finish. This can take somewhere between 5-10 minutes. You want to have it run successfully:

![Success page](images/success.png)

If this is in red, and doesn't say "SUCCEEDED" then check the logs for any errors.

Final bit is updating your DNS config. Make sure to "Copy" the DNS settings generated from the "Application Information" page:

![DNS Settings](images/dns_settings.png)

Save the contents to a new file, for example `dns_update.txt`. The contents should look something like:

```
wafrn.example.com. A 169.254.10.11
bluesky.example.com. A 169.254.10.11
*.bluesky.example.com. A 169.254.10.11
wafrn.example.com. TXT "v=spf1 include:rp.oracleemaildelivery.com include:ap.rp.oracleemaildelivery.com include:eu.rp.oracleemaildelivery.com ~all"
abcdeFGHijKLmnOP._domainkey.wafrn.example.com. CNAME abcdeFGHijKLmnOP.wafrn.example.com.dkim.mrs1.oracleemaildelivery.com
```

Once this file is saved open up the management config website of your DNS provider and import the file above.

If all is well, after a couple more minutes you should be able to access your website on the domain configured by pressing the "Open WAFRN" button. If it doesn't work you either need to wait a bit more, or check [the logs](#logging) to see what's up.

To login you can obtain the administrator password from the same page you got your DNS settings.

Congratulations and Happy WAFRNing!

### Oracle Cloud Shell

OCI has a built-in shell that you can use to connect to and manage instances. To access click on the Cloud Shell button in the corner:

![Cloud Shell](images/cloud_shell.png)

If you asked the script to generate an SSH key for yourself you can install that key onto Oracle Cloud easily:

```
STACK_ID=`oci resource-manager stack list -c $OCI_TENANCY | jq -r ".data[0].id"`
oci resource-manager stack get-stack-tf-state --stack-id $STACK_ID --file - | jq -r '.outputs.generated_private_key_pem.value' > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
```

(the first line only works if you have a single stack installed, otherwise provide the Wafrn one manually)

Once you have done this you should be able to `ssh ubuntu@<your_instance_ip>` and connect to the box.

If you have provided a public key by yourself you will need to install the relevant private key manually before you can access your instance from the Cloud Shell

### Update Wafrn

To update Wafrn follow the steps below:

1. Connect to your instance through ssh. Either follow the Cloud Shell setup above, or manually using openssh, PuTTY or similar tools

2. Run the following:

```bash
sudo su -l wafrn
~/wafrn/install/manage.sh backup
~/wafrn/install/manage.sh update
```

### Update Infrastructure



## Features

The following features are included and will be deployed by the package:

### Wafrn

### Bluesky

### Emails

### On-site backups

### Off-site backups

### Logging

## FAQ

### Is this really free?

You need a domain name you control which you might get for free, but usually they cost a few of your local currency each year. You also need to accept Oracle Cloud Infrastructure's Terms and Conditions which might or might not sell your soul to the devil. A small price to pay though.

Also you will need a Credit or Debit card during the signup for verification, and around $1/£1/€1 will be locked on it during the verification process which will be refunded later.

# LICENSE

Licensed under the AGPLv3

Files are based on [Oracle's Always Free CloudNative example](https://github.com/oracle-quickstart/oci-cloudnative/tree/master/deploy/basic) licensed under the UPL 1.0

[magic_button]: https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg
[magic_wafrn_basic_stack]: https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/sztupy/wafrn-opentofu/releases/latest/download/wafrn-opentofu-latest.zip
