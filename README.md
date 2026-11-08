# Echo Tester with FastPlaz

Echo is a small HTTP echo server built with [FastPlaz](https://github.com/fastplaz/fastplaz). It returns whatever you send, as JSON: query string, form fields and raw body. Use it to test webhooks, API clients, Postman collections or a reverse proxy setup.

One binary runs in two modes:

- **Standalone**: run `echo.bin` and it serves HTTP by itself on `http://127.0.0.1:17845/`.
- **CGI**: put it on Apache and it runs as a regular CGI program.

## Contents

- [Quick start](#quick-start)
- [Usage](#usage)
- [Deployment](#deployment)
- [Build from source](#build-from-source)
- [Configuration](#configuration)
- [Deploy with Docker](#deploy-with-docker)
- [References](#references)

## Quick start

1. [Build](#build-from-source) `public_html/echo.bin`.
2. Run it:

   ```
   $ cd public_html
   $ ./echo.bin
   ```

   ![Standalone mode](img/standalone.png)

3. Open [http://127.0.0.1:17845/?var1=value1&var2=value2](http://127.0.0.1:17845/?var1=value1&var2=value2) in your browser.

Press Ctrl+C to stop.

> **Windows:** cmd and PowerShell do not run a file with the `.bin` extension. Run it from Git Bash (`./echo.bin`), or copy it to `echo.exe` and run that.

## Usage

Echo accepts `GET`, `POST`, `PUT`, `PATCH` and `DELETE`.

| Field | Content |
|---|---|
| `code` | always `0` |
| `sitename` | `systems/sitename` from `config.json` |
| `method` | the request method; not included for `GET` |
| `GET` | query string fields |
| `POST` | form fields (`application/x-www-form-urlencoded` or `multipart/form-data`), for every method except `GET` |
| `RAW_BODY` | the request body: as is when it is valid JSON, base64 encoded otherwise |
| `time` | processing time |

Fields without a value are left out.

### Examples

Query string:

```
$ curl "http://127.0.0.1:17845/?var1=value1&var2=value2"
{ "code" : 0, "sitename" : "Echo Tester for FastPlaz", "GET" : { "var1" : "value1", "var2" : "value2" }, "time" : "6ms" }
```

Form:

```
$ curl -X POST -d "name=luri&city=jakarta" "http://127.0.0.1:17845/"
{ "code" : 0, "sitename" : "Echo Tester for FastPlaz", "method" : "POST", "POST" : { "name" : "luri", "city" : "jakarta" }, "RAW_BODY" : "bmFtZT1sdXJpJmNpdHk9amFrYXJ0YQ==", "time" : "6ms" }
```

JSON body:

```
$ curl -X POST -H "Content-Type: application/json" -d '{"id":1,"tags":["a","b"]}' "http://127.0.0.1:17845/"
{ "code" : 0, "sitename" : "Echo Tester for FastPlaz", "method" : "POST", "RAW_BODY" : { "id" : 1, "tags" : ["a", "b"] }, "time" : "0ms" }
```

PUT and DELETE:

```
$ curl -X PUT -d "name=luri" "http://127.0.0.1:17845/?id=1"
{ "code" : 0, "sitename" : "Echo Tester for FastPlaz", "method" : "PUT", "GET" : { "id" : "1" }, "POST" : { "name" : "luri" }, "RAW_BODY" : "bmFtZT1sdXJp", "time" : "0ms" }

$ curl -X DELETE "http://127.0.0.1:17845/?id=1"
{ "code" : 0, "sitename" : "Echo Tester for FastPlaz", "method" : "DELETE", "GET" : { "id" : "1" }, "time" : "6ms" }
```

More examples are in [`source/test/api.http`](source/test/api.http). The VS Code REST Client extension can run that file.

From the browser:

![Example from browser](img/img01.png)

From curl:

![from Curl in console](img/img02.png)

From Postman:

![from Postman](img/img03.png)

## Deployment

### Standalone behind nginx or Apache

Run `echo.bin` as a service and let nginx or Apache forward requests to it:

1. Keep `address` at `127.0.0.1` so that only the proxy can reach Echo.
2. Set `trust_proxy` to `true`, so that Echo reads the client IP and HTTPS from the `X-Forwarded-*` headers.
3. Do not let the proxy serve `config/` and `ztemp/`.

The FastPlaz guide [Standalone HTTP Mode - Deployment](https://github.com/fastplaz/fastplaz/blob/master/docs/STANDALONE-deployment.md) has nginx and Apache configurations, and service examples for systemd, launchd and Windows (NSSM).

### CGI on Apache (shared hosting, cPanel)

Requirements: Apache with `mod_cgi` and `mod_rewrite`, `AllowOverride All` for the directory, and an `echo.bin` built for the server's OS (usually Linux).

1. Upload everything in `public_html/` to the website's document root, for example `/home/username/public_html/`. The included `.htaccess` sends every request to `echo.bin`.
2. Make the binary executable and the temp folder writable by the web server:

   ```
   $ chmod 755 echo.bin
   $ chmod -R 775 ztemp/
   ```

3. Open `http://yourdomain/?var1=value1&var2=value2`.

The same binary detects that it was started by the web server (`GATEWAY_INTERFACE` is set) and runs as CGI. No setting is needed.

## Build from source

Requirements: [Free Pascal](https://www.freepascal.org/) 3.2.2 or newer and the [FastPlaz](https://github.com/fastplaz/fastplaz) source.

`source/echo/extra.cfg` expects FastPlaz in `vendors/fastplaz`, next to this repository:

```
projects/
  echo/            <- this repository
  vendors/
    fastplaz/      <- https://github.com/fastplaz/fastplaz
```

```
$ git clone https://github.com/fastplaz/fastplaz.git vendors/fastplaz
```

If your copy is elsewhere, edit the `-Fu../../../vendors/fastplaz/...` lines in `extra.cfg`.

Compile:

```
$ cd source/echo
$ ./build.sh
```

The binary is written to `public_html/echo.bin`.

`build.sh` creates the unit output directory `lib/<cpu>-<os>/` and then runs `fpc echo.lpr @extra.cfg`. If you call `fpc` yourself, create that directory first, for example `lib/x86_64-win64` or `lib/x86_64-linux`.

With Lazarus, open `source/echo/echo.lpi`. It requires the `fastplaz_runtime` package.

## Configuration

Settings are in `public_html/config/config.json`:

```json
"systems" : {
  "sitename" : "Echo Tester for FastPlaz",
  "debug" : true,
  "trust_proxy" : false,
  "server" : {
    "mode" : "http",
    "address" : "127.0.0.1",
    "port" : 17845,
    "static" : false,
    "max_requests" : 0
  }
}
```

| Key | Meaning |
|---|---|
| `sitename` | returned as `sitename` in every response |
| `debug` | shows error details, including a stack trace; set to `false` on a public server |
| `trust_proxy` | read the client IP and HTTPS from `X-Forwarded-*`; enable only behind a proxy |
| `server.mode` | `http` (standalone) or `cgi` |
| `server.address`, `server.port` | listen address and port in standalone mode |
| `server.static` | serve static files; leave `false` when the proxy serves them |
| `server.max_requests` | exit after N requests so that the service manager starts a fresh process; `0` = never |

Command line options override the file:

```
$ ./echo.bin --port=8081 --address=0.0.0.0
```

Available options: `--mode=cgi|http`, `--port=N`, `--address=IP`, `--static=on|off`, `--max-requests=N`, `--root=<dir>`.

## Deploy with Docker

It is easy to deploy this project via Docker. We have prepared [FastPlaz image in docker hub](https://hub.docker.com/u/fastplaz/).

**Follow this step:**

Build docker image:

```
# cd docker
# ./build.sh
```

if successfull, run container:

```
# ./run.sh
```

then you should see this result

![from Postman](img/img04.png)

## References

- [FastPlaz Documentation](https://fastplaz.github.io)
- [Tutorial Build FastPlaz Echo Project with Docker](https://medium.com/@luridarmawan/build-fastplaz-echo-project-with-docker-1271aea5f04d)


Semangat ....!
