# Acq scenarios

## Running fetchers as K8s cronJobs

Further info:

* https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/


### Sample cronJob config file

Cron jobs require a config file. The YAML file template can be something like:

` -- application/job/cronjob.yaml --
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"   # same as cron...
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
`

## Creating a cronjob

`
$> kubectl create -f <path/to>/cronjob.yaml
cronjob "hello" created
`

## Getting the status of a cron job

`
$> kubectl get cronjob hello
NAME      SCHEDULE      SUSPEND   ACTIVE    LAST-SCHEDULE
hello     */1 * * * *   False     0         Mon, 29 Aug 2016 14:34:00 -0700
`

## Deleting a cron job

To delete a cron job:

`
$> kubectl delete cronjob hello
cronjob "hello" deleted
`

