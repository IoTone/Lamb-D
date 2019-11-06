# Overview

An AWS Lambda Runtime for Dlang

## Building

- Install the dependences: sh ./setup_external_deps.sh
- Add your lambda implementation into bootstrap.d
- type: dub --compiler=gdc or dub --compiler=ldc2

## Testing

For verification of your Lamb-D in a local serverless style, try:

- sh ./setenv_fake_lambdaenv.sh
- dub test

TODO: Add some better testing facilities.

## Deploying

- Create an AWS Lambda with a Custom Runtime
- Run the packager: sh ./packager.sh
- Copy your lambda.zip into your AWS Lambda instance on AWS.  TODO: Add some more details on the setup.

## Inspirations

- Cramda, a Crystal language based custom runtime https://github.com/lambci/crambda
- Nim AWS Lambda custom runtime https://github.com/lambci/awslambda.nim
