# Password of Root User

## Steps

Enable maintenance page

This will generate new random pwd and save it to SSM
`./aws/infrastructure/tf.sh dev database apply -replace='random_password.runningdinner-db-password-admin'`

New deployment will automatically pick up this one

Disable maintenance page

# Password of App User

## Steps

Enable maintenance page

This will generate new random pwd and save it to SSM
`./aws/infrastructure/tf.sh dev database apply -replace='random_password.database-password-app'`

Use new generated pwd and execute this in Postgres Cluster with root user:
`ALTER USER runningdinner WITH PASSWORD 'new-password-here';`

Execute new deployment

Disable maintenance page
