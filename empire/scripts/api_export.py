from pathlib import Path

import yaml

from empire.server.api.app import initialize
from empire.server.server import set_main


def api_export(args):
    set_main(args)
    app = initialize(run=False)
    openapi = app.openapi()
    version = openapi.get("openapi", "unknown version")

    print(f"writing openapi spec v{version}")
    file_path = Path("docs/openapi.yaml")

    file_path.write_text(yaml.dump(openapi, sort_keys=False))
    print(f"spec written to {file_path}")

    gitbook_page = Path("docs/restful-api/openapi.md")
    with gitbook_page.open("w") as f:
        for path, data in openapi["paths"].items():
            for method, _ in data.items():
                # {% swagger src="sample.yaml" path="/stars" method="post" %} sample.yaml {% endswagger %}
                f.write(f"{{% swagger src=\"./openapi.yaml\" path=\"{path}\" method=\"{method}\" %}} [./openapi.yaml](./openapi.yaml) {{% endswagger %}}\n")

    print(f"gitbook page written to {gitbook_page}")
