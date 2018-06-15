# Port Cost Watch

A flexible system for proforma disbursements estimates.

## Docker based development

Copy the `dot_env_template` file to `.env` and fill in the secrets

`make dev` will start the development
environment.

`make restore-dump` will setup the database with a staging dump

You'll need to add entries to your `/etc/hosts` file to access the service, e.g. `127.0.0.1 localhost monsontest.pcw.a3`

After that you'll be able to access the service at http://monsontest.pcw.a3:3000

## Running the test suite

`make t`

## Architecture

Port tariffication is implemented using javascript formulas, and can thus
be executed both in the browser for live estimate manipulation and server-side,
using an embedded V8 engine.

Services assigned to ports and terminals are expected to change over time (new
laws, tariff updates, etc...) so they behave like a loose and changing schema
for disbursements.

Each disbursement revision "crystalizes" the current schema using the flexibility
of PostgreSQL's hstore extension, so that it becomes a self-contained entity.
