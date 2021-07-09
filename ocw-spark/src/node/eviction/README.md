# Eviction Service

This directory contains Azure functions that are intended to implement compensation strategies related to Spot VM evictions.

## Dependencies

The functions assume the `infra-cd.yml` deployment has already been executed. This will create the function service plan and app that will host these functions.

Other dependencies include (these are already installed with the dev container):
1. Node v14
2. Azure Functions Core Tools v3

## Build

Build will compile the typescript to standard javascript within `.dist` directory.

`npm run build`

## Start

Start will start the azure function runtime and listen on port 7071 for function http requests. The following URL's should be accessible

- EvictionHandler: [GET,POST] http://localhost:7071/api/EvictionHandler

`npm run start`

## Deploy

The github action [`eviction-cd.yml`](../../../.github/workflows/eviction-cd.yml) will deploy the functions within this project into the function app provisioned by the infrastructure deployment. The function app is expected to have name of `fn-evict-[organisaton_name]-[env_name]` where `organisaton_name` and `env_name` are configured with [`main.json`](../../../build/configurations/main.json).

## Local Testing

The function expects the following environment variables storing information about a service principal with privileges to start VMs in the subscription:

- CLIENT_ID
- SECRET
- TENANT_ID
- SUBSCRIPTION_ID
