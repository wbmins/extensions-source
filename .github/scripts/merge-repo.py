import gzip
import json
from pathlib import Path
import re

from google.protobuf import json_format

import index_pb2

REMOTE_REPO: Path = Path.cwd()
LOCAL_REPO: Path = REMOTE_REPO.parent.joinpath("repo/")

LANGUAGE_REGEX = re.compile(r"tachiyomi-([^.]+)")


with LOCAL_REPO.joinpath("index.json").open() as f:
    local_index = json_format.Parse(f.read(), index_pb2.Index())

index = index_pb2.Index(
    name="E-Hentai",
    badgeLabel="EH",
    signingKey="b5cfb459889cc0daa8c76d86b6cd1a7bbad5143286c6afa6c68a1ee6cd756220",
    contact=index_pb2.Contact(
        website="https://e-hentai.org", discord="https://ehwiki.org/wiki/Talk:Main_Page"
    ),
    extensionList=local_index.extensionList,
)

with REMOTE_REPO.joinpath("index.pb").open("wb") as f:
    f.write(gzip.compress(index.SerializeToString()))


def get_legacy_lang(ext) -> str:
    apk_filename = ext.resources.apkUrl.split("/")[-1]
    lang = LANGUAGE_REGEX.search(apk_filename).group(1)
    if len(ext.sources) == 1:
        source_language = ext.sources[0].language
        if (
            source_language != lang
            and source_language not in {"all", "other"}
            and lang not in {"all", "other"}
        ):
            lang = source_language
    return lang


legacy_json_index = [
    {
        "name": f"Tachiyomi: {ext.name}",
        "pkg": ext.packageName,
        "apk": ext.resources.apkUrl.split("/")[-1],
        "lang": get_legacy_lang(ext),
        "code": ext.versionCode,
        "version": ext.versionName,
        "nsfw": 1 if ext.contentWarning > 2 else 0,
        "sources": [
            {
                "name": source.name,
                "lang": source.language,
                "id": str(source.id),
                "baseUrl": source.homeUrl,
            }
            for source in ext.sources
        ],
    }
    for ext in local_index.extensionList.extensions
]

with REMOTE_REPO.joinpath("index.min.json").open("w", encoding="utf-8") as f:
    json.dump(legacy_json_index, f, ensure_ascii=False, separators=(",", ":"))