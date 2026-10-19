{
  lib,
  python3Packages,
  fetchPypi,
  fetchFromGitHub,
  ...
}:

let
  pypi =
    pname: version: hash:
    fetchPypi {
      inherit pname version hash;
    };

  python = python3Packages.python.override {
    self = python;
    packageOverrides = final: prev: {
      starlette = prev.starlette.overridePythonAttrs (old: rec {
        version = "1.9.0";
        src = pypi "starlette" version "sha256-PZMd4kbthw41zmBZdEQIFu+JXlkvJV0Tls/fGR1MQxg=";
        optional-dependencies = old.optional-dependencies // {
          full = old.optional-dependencies.full ++ [
            final.httpx2
            final.opentelemetry-api
          ];
        };
        nativeCheckInputs = old.nativeCheckInputs ++ [
          final.httpx2
          final.opentelemetry-api
          final.opentelemetry-sdk
        ];
      });

      fastapi = prev.fastapi.overridePythonAttrs (old: {
        nativeCheckInputs = old.nativeCheckInputs ++ [ final.httpx2 ];
        disabledTests = old.disabledTests ++ [
          "test_header_param_model_invalid"
          "test_header_param_model_no_underscore"
        ];
      });

      sse-starlette = prev.sse-starlette.overridePythonAttrs (old: {
        nativeCheckInputs = old.nativeCheckInputs ++ [ final.httpx2 ];
        disabledTests = old.disabledTests ++ [
          "test_response_send_whenValidInput_thenGeneratesExpectedOutput"
          "test_eventSourceResponse_whenUsingMemoryChannel_thenHandlesAsyncQueueCorrectly"
        ];
      });

      python-multipart =prev.python-multipart.overridePythonAttrs (old: rec {
        version = "0.0.32";
        src = pypi "python_multipart" version "sha256-vlS38/oWe7g+T82Ta4h7cI9OV/51kRwCrr9T76+Nk44=";
        patches = [ ];
      });

      uncalled-for = prev.uncalled-for.overridePythonAttrs (old: rec {
        version = "0.4.1";
        src = pypi "uncalled_for" version "sha256-ZBKxnRsefUMZgf7gH4tHvngC9IMopIy+lgOs7nV+xVM=";
      });

      py-key-value-aio = prev.py-key-value-aio.overridePythonAttrs (old: rec {
        version = "0.4.6";
        src = pypi "py_key_value_aio" version "sha256-JnwDw+JMuZ0wl2Evilz9jhF4XGopdeJy2w4wPqGFC/0=";
        sourceRoot = null;
        postPatch = ''
          substituteInPlace pyproject.toml --replace-fail '"uv_build>=0.11.4,<0.12"' '"uv_build"'
        '';
        dependencies = with final; [
          beartype
          typing-extensions
        ];
        doCheck = false;
      });

      httpcore2 = final.buildPythonPackage rec {
        pname = "httpcore2";
        version = "2.14.0";
        pyproject = true;
        src = pypi pname version "sha256-T1ehqCSf5q9YnZNc/UVvHRO73LDw/HKvkUI2j8lIEdc=";
        build-system = with final; [
          hatchling
          hatch-fancy-pypi-readme
          uv-dynamic-versioning
        ];
        dependencies = with final; [
          h11
          truststore
        ];
        postPatch = ''
          substituteInPlace pyproject.toml --replace-fail '"uv-dynamic-versioning>=0.14.1"' '"uv-dynamic-versioning"'
        '';
        pythonImportsCheck = [ "httpcore2" ];
      };

      httpx2 = final.buildPythonPackage rec {
        pname = "httpx2";
        version = "2.14.0";
        pyproject = true;
        src = pypi pname version "sha256-R61ho8QCgs2NDcljEVMfAPW/xxoGbG/js22PY/ueT24=";
        build-system = with final; [
          hatchling
          hatch-fancy-pypi-readme
          uv-dynamic-versioning
        ];
        postPatch = ''
          substituteInPlace pyproject.toml --replace-fail '"uv-dynamic-versioning>=0.14.1"' '"uv-dynamic-versioning"'
        '';
        pythonRelaxDeps = [ "idna" ];
        dependencies = with final; [
          anyio
          httpcore2
          idna
          truststore
        ];
        pythonImportsCheck = [ "httpx2" ];
      };

      mcp-types = final.buildPythonPackage rec {
        pname = "mcp-types";
        version = "2.3.0";
        pyproject = true;
        src = pypi "mcp_types" version "sha256-0eRlSe2zXuGalJQPzubRrd1+WJq36pLdqD9dhHgfw2I=";
        build-system = with final; [
          hatchling
          uv-dynamic-versioning
        ];
        dependencies = with final; [
          pydantic
          typing-extensions
        ];
        pythonImportsCheck = [ "mcp_types" ];
      };

      mcp = prev.mcp.overridePythonAttrs (old: rec {
        version = "2.3.0";
        src = pypi "mcp" version "sha256-ixR6UEQc8FnciMaE4K7tNofwqg85xs3nuQMw7/0rNNg=";
        dependencies = with final; [
          anyio
          httpx2
          jsonschema
          mcp-types
          opentelemetry-api
          pydantic
          pyjwt
          python-multipart
          sse-starlette
          starlette
          typing-extensions
          typing-inspection
          uvicorn
        ]
        ++ pyjwt.optional-dependencies.crypto;
        postPatch = "";
        nativeCheckInputs =
          old.nativeCheckInputs
          ++ (with final; [
            blockbuster
            logfire
            opentelemetry-sdk
            pillow
            trio
          ]);
        disabledTests = old.disabledTests ++ [
          "test_client_with_stdio_parameters_launches_the_server_as_a_subprocess"
          "test_a_tool_spawned_childs_stdout_writes_never_reach_the_wire"
          "test_call_tool_accepts_a_null_structured_content_the_output_schema_permits"
        ];
        disabledTestPaths = [
          "tests/docs"
          "tests/examples"
          "tests/interaction/test_coverage.py"
          "tests/interaction/transports/test_stdio.py"
        ];
      });

      fastmcp-slim = final.buildPythonPackage rec {
        pname = "fastmcp-slim";
        version = "4.0.11";
        pyproject = true;
        src = pypi "fastmcp_slim" version "sha256-kVKqx02IN7w3V29fPYPxdWclCp382BhxM8Q/qqqd0G8=";
        build-system = with final; [
          hatchling
          uv-dynamic-versioning
        ];
        pythonRelaxDeps = [ "aiofile" ];
        dependencies =
          with final;
          [
            mcp-types
            platformdirs
            pydantic
            pydantic-settings
            python-dotenv
            rich
            typing-extensions
            authlib
            cyclopts
            exceptiongroup
            griffelib
            httpx2
            joserfc
            jsonref
            jsonschema-path
            mcp
            openapi-pydantic
            opentelemetry-api
            packaging
            py-key-value-aio
            pyperclip
            python-multipart
            pyyaml
            starlette
            uncalled-for
            uvicorn
            watchfiles
            websockets
          ]
          ++ pydantic.optional-dependencies.email
          ++ py-key-value-aio.optional-dependencies.filetree
          ++ py-key-value-aio.optional-dependencies.keyring
          ++ py-key-value-aio.optional-dependencies.memory;
        pythonImportsCheck = [ "fastmcp" ];
      };

      fastmcp = final.buildPythonPackage rec {
        pname = "fastmcp";
        version = "4.0.11";
        pyproject = true;
        src = pypi pname version "sha256-Vfx7jiXU+DZYGLqT9wCNG25kbOf+iuSTQmhyQ8y++fI=";
        build-system = with final; [
          hatchling
          uv-dynamic-versioning
        ];
        dependencies = [ final.fastmcp-slim ];
        pythonImportsCheck = [ "fastmcp" ];
      };

      clickhouse-connect = prev.clickhouse-connect.overridePythonAttrs (old: rec {
        version = "1.11.0";
        src = fetchFromGitHub {
          owner = "ClickHouse";
          repo = "clickhouse-connect";
          tag = "v${version}";
          hash = "sha256-c5iFLxg37FZybQz2mTtYBnyprPx5mzk0m+Si4V1WcNQ=";
        };
        format = null;
        pyproject = true;
        build-system = with final; [
          setuptools
          cython
        ];
        propagatedBuildInputs = [ ];
        dependencies = with final; [
          certifi
          urllib3
          backports-zstd
          lz4
        ];
        nativeCheckInputs =
          old.nativeCheckInputs
          ++ (with final; [
            pytest-xdist
            pytest-asyncio
            pytest-mock
            aiohttp
            alembic
            pyarrow
          ]);
        preCheck = ''
          rm -rf clickhouse_connect
        '';
        disabledTestPaths = old.disabledTestPaths ++ [ "tests/test_bare_install.py" ];
      });
    };
  };

  pp = python.pkgs;
in
pp.buildPythonApplication rec {
  pname = "mcp-clickhouse";
  version = "0.7.0";
  pyproject = true;

  src = pypi "mcp_clickhouse" version "sha256-IWjk3dPnBO+XHBL7C7FbhedEcL+p49GQopuJVJkel48=";

  build-system = [ pp.hatchling ];

  dependencies = with pp; [
    fastmcp
    clickhouse-connect
    python-dotenv
    truststore
    cachetools
    uvicorn
    simplejson
  ];

  nativeCheckInputs = with pp; [
    pytestCheckHook
    pytest-asyncio
  ];

  preCheck = ''
    export CLICKHOUSE_HOST=localhost
    export CLICKHOUSE_PORT=8123
    export CLICKHOUSE_USER=default
    export CLICKHOUSE_PASSWORD=SYNTHETIC-FIXTURE
    export CLICKHOUSE_SECURE=false
    export CLICKHOUSE_VERIFY=false
  '';

  disabledTestPaths = [
    "tests/test_tool.py"
    "tests/test_pagination.py"
  ];

  disabledTests = [
    "test_tool_call_with_overrides"
    "test_tool_call_without_overrides"
    "test_concurrent_queries"
    "test_list_databases"
    "test_list_tables_basic"
    "test_list_tables_with_like_filter"
    "test_list_tables_with_not_like_filter"
    "test_run_select_query_error"
    "test_run_select_query_success"
    "test_run_select_query_with_aggregation"
    "test_run_select_query_with_join"
    "test_system_database_access"
    "test_table_metadata_details"
    "test_parameter_names_do_not_trigger_drop_guard"
    "test_parameter_values_stay_out_of_normal_query_logs"
    "test_parameterized_writes_preserve_access_gates"
    "test_registered_query_accepts_driver_supported_parameter_names"
    "test_registered_query_accepts_literal_and_comment_braces"
    "test_registered_query_accepts_long_enum_placeholder"
    "test_registered_query_accepts_omitted_or_empty_params"
    "test_registered_query_binds_1024_element_vector"
    "test_registered_query_binds_json_values"
    "test_registered_query_reports_parameter_errors"
    "test_sync_query_binds_parameters"
    "test_typed_parameters_preserve_percent_text"
    "test_import_modes_ignore_hostile_cwd_dotenv_and_use_package_discovery"
    "test_import_modes_without_package_dotenv_fail_closed_from_hostile_cwd"
    "test_auth_provider_resolves_when_transport_app_is_constructed"
    "test_cli_loads_middleware_before_running_server"
    "test_entrypoint_keeps_independent_clickhouse_owners"
    "test_entrypoint_keeps_independent_executor_and_chdb_ownership"
    "test_fresh_submodule_import_preserves_registration_and_exports"
    "test_selected_dotenv_configures_initial_executors_and_http_auth"
    "test_documented_azure_environment_constructs_real_provider"
  ];

  __darwinAllowLocalNetworking = true;

  pythonImportsCheck = [ "mcp_clickhouse" ];

  meta = {
    description = "Official ClickHouse MCP server";
    homepage = "https://github.com/ClickHouse/mcp-clickhouse";
    license = lib.licenses.asl20;
    mainProgram = "mcp-clickhouse";
  };
}
