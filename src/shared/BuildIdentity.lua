-- Source builds are explicitly unidentified until a trusted CI or publish
-- workflow stamps the exact checked-out Git SHA immediately before Rojo.
-- This module has no write API, HTTP requests or gameplay privileges.
return {
    SourceSha = "UNSTAMPED",
    Channel = "SOURCE",
}
