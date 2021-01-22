# increment-semver

Tool for incrementing new semver version numbers by using the increment.build service.

## Purpose

The purpose of this script is to generate a continuously increasing SemVer type version number
for a project, by leveraging the hosted service http://increment.build.(1)
It provides a very good alternative for using "build id" numbers from your CI server as
part of your version number, which for many reasons is a bad practice. (e.g. there is typically
no way to "reset" build-id to zero when you bump a minor or major version. Also, at least on
Azure DevOps, the BuildId sequence is shared among all pipelines in a project, which can make for some
very rapidly increasing numbers).

## Details

It its current form, this script assumes that major.minor versions are managed elsewhere,
and passed in as arguments to this script.

This script then generates(2) a full major.minor.patch version number, using the next unused
available patch number delivered by the increment.build service.

## Dependencies

Apart from obviously requiering bash or a compatible shell, the script depends on the following that might not be default available on your system, especially if running on a minimal build server or in a container: 

- curl
- sha1sum

## Footnotes
1) If you don't want to use the publicly hosted service,you can choose to run your own copy,
on premise or on a cloud of choice, as the increment.build project is Open Source under a MIT license

2) In its current form, this script is designed for use in Azure Devops, but the only concession
to this usage is that the script outputs the result as a console "##vso[task.setvariable ...]"
statement for use in later build stages instead of returning the value. The name of the variable
being set is 'tag', as it is currently used mainly to tag docker images.
