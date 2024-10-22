"""Find glab pipelines that haven't completed a stage."""

import os

import requests


# Replace with your GitLab instance URL
GITLAB_URL = "https://gitlab.example.com"
PROJECT_ID = "12345"  # Replace with your project ID
STAGENAME = "destroy"

API_TOKEN = os.getenv("GITLAB_TOKEN")

HEADERS = {"Private-Token": API_TOKEN}


def get_pipelines(project_id: str) -> list[dict]:
    """Fetch pipelines for a given project."""
    url = f"{GITLAB_URL}/api/v4/projects/{project_id}/pipelines"
    response = requests.get(url, headers=HEADERS)
    response.raise_for_status()

    return response.json()


def get_pipeline_jobs(project_id: str, pipeline_id: int) -> list[dict]:
    """Fetch jobs for a given pipeline."""
    url = (
        f"{GITLAB_URL}/api/v4/projects/"
        f"{project_id}/pipelines/{pipeline_id}/jobs"
    )
    print(f"Hitting API url: {url}")
    response = requests.get(url, headers=HEADERS)
    response.raise_for_status()

    print(f"response: {response.json()}")
    return response.json()


def filter_pipelines_without_stage(
    pipelines: list[dict],
    project_id: str,
    stagename: str,
) -> list[int]:
    """Return list of pipeline IDs missing the stage."""
    missing_stage = []

    for pipeline in pipelines:
        jobs = get_pipeline_jobs(project_id, pipeline["id"])
        stages = {job["stage"] for job in jobs}

        if stagename not in stages:
            missing_stage.append(pipeline["id"])

    return missing_stage


def main() -> None:
    pipelines = get_pipelines(PROJECT_ID)

    if pipelines_without_stage := filter_pipelines_without_stage(
        pipelines, PROJECT_ID, STAGENAME
    ):
        print(
            f"Pipelines missing '{STAGENAME}' stage:", pipelines_without_stage
        )
    else:
        print(f"All pipelines have a '{STAGENAME}' stage.")


if __name__ == "__main__":
    main()
