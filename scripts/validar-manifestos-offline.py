#!/usr/bin/env python3
"""Verifica YAML e invariantes do projeto SEM um cluster Kubernetes.
Dependencia: python3-yaml (PyYAML). Nao valida schema completo Kubernetes.
"""
from pathlib import Path
import sys
import yaml

ROOT = Path(__file__).resolve().parent.parent / "kubernetes"
EXPECTED = {
    "namespace.yaml": ("Namespace", "poi-atividade5"),
    "cpu-deployment.yaml": ("Deployment", "poi-cpu"),
    "cpu-service.yaml": ("Service", "poi-cpu"),
    "memory-deployment.yaml": ("Deployment", "poi-memory"),
    "memory-service.yaml": ("Service", "poi-memory"),
    "io-deployment.yaml": ("Deployment", "poi-io"),
    "io-service.yaml": ("Service", "poi-io"),
}
IMAGES = {
    "poi-cpu": "arthuurvidaal/poi-cpu:atividade4",
    "poi-memory": "arthuurvidaal/poi-memory:atividade4",
    "poi-io": "arthuurvidaal/poi-io:atividade4",
}
PORTS = {"poi-cpu": 30081, "poi-memory": 30082, "poi-io": 30083}

try:
    actual = {p.name for p in ROOT.glob("*.yaml")}
    assert actual == set(EXPECTED), f"Arquivos inesperados ou faltantes: {actual ^ set(EXPECTED)}"
    for filename, (kind, name) in EXPECTED.items():
        with (ROOT / filename).open(encoding="utf-8") as handle:
            docs = list(yaml.safe_load_all(handle))
        assert len(docs) == 1 and isinstance(docs[0], dict), filename
        doc = docs[0]
        assert doc.get("apiVersion") and doc.get("kind") == kind, filename
        meta = doc.get("metadata", {})
        assert isinstance(meta, dict) and meta.get("name") == name, filename
        if kind == "Namespace":
            assert meta.get("name") == "poi-atividade5", filename
        else:
            assert meta.get("namespace") == "poi-atividade5", filename
        if kind == "Deployment":
            spec = doc["spec"]
            assert spec["replicas"] == 1
            labels = spec["template"]["metadata"]["labels"]
            assert spec["selector"]["matchLabels"] == labels == {"app": name}
            container = spec["template"]["spec"]["containers"][0]
            assert container["image"] == IMAGES[name]
            assert container["readinessProbe"]["httpGet"]["path"] == "/health"
            assert container["livenessProbe"]["httpGet"]["path"] == "/health"
            assert container["resources"]["requests"] and container["resources"]["limits"]
            if name == "poi-io":
                volumes = spec["template"]["spec"].get("volumes", [])
                assert any("emptyDir" in v for v in volumes)
        if kind == "Service":
            spec = doc["spec"]
            assert spec["type"] == "NodePort"
            assert spec["selector"] == {"app": name}
            assert spec["ports"][0]["nodePort"] == PORTS[name]
            assert spec["ports"][0]["targetPort"] == "http"
        print(f"OK: {filename} -> {kind}/{name}")
    print("\nOK: 7 manifestos e invariantes do projeto verificados offline.")
except (AssertionError, KeyError, IndexError, TypeError, ValueError, yaml.YAMLError) as exc:
    print(f"FALHA: {exc}", file=sys.stderr)
    sys.exit(1)
