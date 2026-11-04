# jikchin-infra

직친의 AWS 인프라를 관리하는 Terraform 설정입니다. 현재는 프로필 사진을 저장할 S3 버킷을 정의합니다.

## 시작하기

Terraform 1.5 이상과 AWS 자격 증명이 필요합니다. Terraform을 실행하는 IAM 주체에는 S3 버킷과 공개 접근 차단 및 암호화 설정을 관리할 권한이 필요합니다. 백엔드의 사진 업로드에 필요한 `s3:PutObject` 권한과는 별도입니다. AWS 자격 증명을 Terraform 파일이나 Git에 기록하지 마세요.

1. `terraform.tfvars.example`을 `terraform.tfvars`로 복사합니다. `avatar_bucket_name`을 아직 사용되지 않는 전역 고유 버킷 이름으로 바꾸고, 필요하면 리전도 수정합니다.
2. 다음 명령을 순서대로 실행합니다.

   ```powershell
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan
   ```

3. `plan`에서 생성될 리소스와 AWS 계정, 리전을 확인한 뒤 `terraform apply`를 실행합니다. 이미 존재하는 버킷은 자동으로 가져오지 않으므로, 기존 버킷을 관리하려면 먼저 import를 별도로 계획해야 합니다.

`terraform init`으로 생성되는 `.terraform.lock.hcl`은 provider 버전을 고정하므로 Git에 포함합니다. `terraform.tfvars`, `.terraform/`, 상태 파일과 plan 파일은 Git에서 제외합니다.

## 상태와 사진 접근

현재 설정은 Terraform 상태를 로컬에 저장합니다. 상태 파일은 민감한 데이터를 포함할 수 있으므로 안전하게 보관하세요. 협업하기 전에는 접근 제어와 잠금 기능이 있는 원격 상태 저장소를 구성합니다.

사진 버킷의 공개 접근은 차단되어 있습니다. 백엔드가 업로드하려면 별도의 IAM 권한이 필요하고, 앱에서 사진을 표시하려면 CloudFront 같은 별도의 안전한 이미지 제공 방식과 `ASSETS_BASE_URL` 설정이 필요합니다. 이 설정은 이미지 제공 경로나 IAM 사용자를 생성하지 않습니다.
