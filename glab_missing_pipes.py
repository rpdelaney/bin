"""Find GitLab pipelines where a specific stage has not finished."""

import os

import requests


# Replace with your GitLab instance URL
GITLAB_URL = "https://gitlab.example.com"
PROJECT_ID = "12345"  # Replace with your project ID
STAGENAME = "destroy"

API_TOKEN = os.getenv("GITLAB_TOKEN")
if not API_TOKEN:
    msg = "Please set the GITLAB_TOKEN environment variable."
    raise OSError(msg)

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
    jobs = response.json()
    print(f"Retrieved {len(jobs)} jobs for pipeline {pipeline_id}.")

    return jobs


def is_stage_finished(jobs: list[dict], stagename: str) -> bool:
    """
    Determine if the specified stage has finished.

    A stage is finished if all its jobs have statuses:
    'success', 'failed', 'canceled', or 'skipped'.
    """
    finished_statuses = {"success", "failed", "canceled", "skipped"}
    stage_jobs = [job for job in jobs if job["stage"] == stagename]

    if not stage_jobs:
        # Stage does not exist in this pipeline
        return True  # Consider it as finished for this context

    # Check if all jobs in the stage are finished
    for job in stage_jobs:
        if job["status"] not in finished_statuses:
            print(
                f"Job {job['id']} in stage '{stagename}' "
                f"is not finished (status: {job['status']})."
            )
            return False
    return True


def filter_pipelines_stage_not_finished(
    pipelines: list[dict],
    project_id: str,
    stagename: str,
) -> list[int]:
    """Return pipeline IDs where the specified stage has not finished."""
    stage_not_finished = []

    for pipeline in pipelines:
        pipeline_id = pipeline["id"]
        jobs = get_pipeline_jobs(project_id, pipeline_id)
        if not is_stage_finished(jobs, stagename):
            stage_not_finished.append(pipeline_id)

    return stage_not_finished


def main() -> None:
    print("Fetching pipelines...")
    pipelines = get_pipelines(PROJECT_ID)
    print(f"Retrieved {len(pipelines)} pipelines.")

    print(f"Filtering pipelines where stage '{STAGENAME}' has not finished...")

    if pipelines_stage_not_finished := filter_pipelines_stage_not_finished(
        pipelines, PROJECT_ID, STAGENAME
    ):
        print(
            f"Pipelines where stage '{STAGENAME}' has not finished:",
            pipelines_stage_not_finished,
        )
    else:
        print(f"All pipelines have the stage '{STAGENAME}' finished.")


if __name__ == "__main__":
    main()
