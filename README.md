# jikchin-infra

직친의 AWS 인프라를 관리하는 Terraform 설정입니다. 프로필 사진 저장용 S3 버킷과 배포용 EC2 서버를 정의합니다.

## 파일 구성

- `network.tf`: VPC, 서브넷, 인터넷 게이트웨이와 라우팅
- `ec2.tf`: EC2, Elastic IP와 서버 보안 그룹
- `iam.tf`: 서버의 IAM 역할과 권한
- `s3.tf`: 프로필 사진 버킷
- `providers.tf`, `versions.tf`: AWS provider, Terraform 버전과 원격 상태 설정
- `variables.tf`, `outputs.tf`: 입력 변수와 출력값
- `bootstrap/`: Terraform 상태 저장용 S3 버킷을 관리하는 별도 구성

## 배포용 EC2 서버

- 서울 리전 기본값으로 별도 VPC와 퍼블릭 서브넷, 인터넷 게이트웨이, 보안 그룹, EC2 한 대를 만듭니다. 기본 사양은 x86_64 `t3.small`(메모리 2 GiB), 암호화된 20 GiB gp3 루트 볼륨입니다. `server_instance_type`, `server_root_volume_size`로 변경할 수 있습니다. AMI는 x86_64이므로 인스턴스 유형도 해당 아키텍처를 지원해야 합니다.
- 인스턴스에 Elastic IP를 연결하므로 중지 후 다시 시작해도 공인 IPv4 주소를 유지합니다. Elastic IP를 해제하거나 새로 생성하면 주소가 바뀔 수 있습니다. EC2, EBS, 공인 IPv4 및 데이터 전송 등에는 비용이 발생합니다.
- 외부 인바운드는 TCP 80, 443만 허용합니다. SSH 키와 22번 포트는 사용하지 않으며, Systems Manager Session Manager 접속용 인스턴스 프로파일을 연결합니다. 운영자에게도 Session Manager 사용 권한이 필요합니다. 서버가 SSM에 등록된 후 `aws ssm start-session --region ap-northeast-2 --target <server_instance_id>`로 접속할 수 있습니다. 인스턴스는 SSM을 포함한 AWS 서비스에 인터넷으로 연결합니다.
- 인스턴스 역할에는 기존 사진 버킷의 `avatars/users/*`에 대한 `s3:PutObject` 권한이 있습니다. IMDSv2를 필수로 하며, 컨테이너에서 인스턴스 역할을 사용할 수 있도록 메타데이터 응답 홉 제한을 2로 설정합니다. 따라서 서버에서 실행하는 컨테이너에도 이 역할의 권한이 제공될 수 있습니다.
- 이 구성은 서버만 준비하며 앱, Docker, MySQL, 리버스 프록시, 도메인, TLS 인증서와 배포 자동화를 설치하거나 설정하지 않습니다. 현재 앱 Compose는 기본적으로 `127.0.0.1:8080`에 바인딩됩니다. 외부 서비스에는 별도로 80/443 리버스 프록시와 HTTPS를 구성하고 앱 설정 및 비밀값을 안전하게 제공해야 합니다. 8080과 MySQL 포트는 외부에 열지 않습니다.
- `t3.small`은 초기 저부하용이며 Spring과 MySQL을 함께 실행하거나 서버에서 Docker 이미지를 빌드할 때 메모리가 부족할 수 있습니다. 실제 부하를 확인해 사양을 조정하고, 이미지 빌드는 별도 환경에서 수행하는 것을 권장합니다.
- 루트 볼륨은 인스턴스 종료 시 삭제됩니다. MySQL을 이 볼륨에 저장한다면 별도 백업과 복구 절차가 필요합니다. 자동 백업과 고가용성은 구성하지 않았습니다.
- AMI는 AWS의 최신 Amazon Linux 2023 SSM 파라미터를 참조합니다. 이후 AMI가 갱신되면 Terraform이 인스턴스 교체를 계획할 수 있으므로 `plan`에서 교체와 데이터 영향을 반드시 확인하세요.

기존 `avatar_bucket_name`과 원격 상태 설정은 그대로 유지합니다. 예시 변수 파일에서 EC2 사양은 선택 사항이며, 적용 후 `server_instance_id`와 `server_public_ip` 출력으로 인스턴스 ID와 Elastic IP를 확인할 수 있습니다. 현재 설정을 `apply`하면 기존 사진 버킷과 함께 EC2 관련 리소스도 관리하므로 적용 전에 전체 변경 사항을 확인해야 합니다.

## 원격 상태 저장소 준비

Terraform 1.10 이상이 필요합니다. 상태는 사진 버킷과 **별개의 S3 버킷**에 저장하고 S3 잠금 파일(`.tflock`)로 동시 변경을 방지합니다. DynamoDB 잠금 방식은 Terraform에서 사용 중단 예정이므로 사용하지 않습니다.

백엔드 버킷은 해당 백엔드를 사용하는 Terraform 설정보다 먼저 존재해야 합니다. `bootstrap/`의 별도 Terraform 구성으로 `ap-northeast-2`에 생성하며 퍼블릭 액세스 차단, 버전 관리, 기본 암호화(SSE-S3), Terraform에서의 실수로 인한 삭제 방지를 설정합니다. 이미 생성된 버킷은 다시 만들지 않습니다. 상태에는 민감한 정보가 포함될 수 있으므로 접근을 필요한 사용자에게만 허용합니다.

모든 작업자는 같은 버킷과 리전, 상태 경로(`jikchin-infra/terraform.tfstate`)를 사용해야 합니다. AWS 자격 증명은 AWS CLI 프로필이나 환경 변수 등 기본 자격 증명 체인으로 제공합니다. Terraform 파일이나 Git에 자격 증명을 넣지 마세요. 백엔드 설정과 plan 파일, 로컬 백업도 민감할 수 있습니다.

각 작업자의 IAM 권한에는 버킷에 대한 `s3:ListBucket`, 상태 객체에 대한 `s3:GetObject`와 `s3:PutObject`, 잠금 객체에 대한 `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`가 필요합니다. 사진 버킷 상태는 `jikchin-infra/terraform.tfstate`, 상태 버킷의 상태는 `bootstrap/terraform.tfstate`에 각각 저장하며 잠금 객체는 각 경로의 끝에 `.tflock`이 붙습니다. 아래 구성은 기본 workspace 기준입니다. AWS 리소스를 관리할 권한은 별도로 필요합니다. 권한 상세는 [Terraform S3 백엔드 문서](https://developer.hashicorp.com/terraform/language/backend/s3)를 참고하세요.

## 기존 로컬 상태 이전 참고

기존 사진 버킷 상태와 `bootstrap/` 상태는 이미 원격 S3로 이전했습니다. 다음은 새로운 로컬 상태를 다른 원격 저장소로 옮길 때의 참고 절차이며, 다른 PC에서 현재 원격 상태에 접속할 때 실행하지 않습니다. 이전 중에는 다른 PC에서 Terraform을 실행하지 마세요. 원격 경로에 이미 상태가 있다면 덮어쓰지 말고 두 상태의 출처를 먼저 확인합니다. 이 절차는 기본 workspace를 사용합니다.

1. 기존 `terraform.tfstate`와 관련 백업을 안전한 별도 위치에 복사합니다. Git이나 채팅에 올리지 않습니다.
2. 이 디렉터리에서 `backend.hcl.example`을 `backend.hcl`로 복사하고 실제 상태 버킷 이름을 입력합니다. `backend.hcl`은 Git에서 제외됩니다.
3. 이미 상태 버킷이 준비된 것을 확인한 다음, 로컬 상태가 있는 디렉터리에서 다음을 실행하고 이전 확인 질문에 응답합니다.

   ```powershell
   terraform init -migrate-state '-backend-config=backend.hcl'
   terraform state list
   terraform plan
   ```

4. 원격 상태의 리소스 목록과 plan을 이전 상태와 비교합니다. 예상하지 않은 생성·삭제가 있으면 `apply`하지 말고 원인을 확인하세요. 이전 완료를 확인할 때까지 로컬 상태와 백업을 보관합니다.

`-reconfigure`는 기존 백엔드 설정을 잊고 다시 구성하므로 위 이전 단계 대신 사용하지 않습니다. `terraform state push -force`나 상태 파일 직접 업로드로 이전하지 않습니다.

## 다른 PC에서 시작하기

같은 레포와 동일한 AWS 계정·권한, 기존 작업 환경의 `backend.hcl`에 적힌 상태 버킷 이름을 사용합니다. 로컬 자격 증명과 `terraform.tfvars`는 각자 준비합니다.

```powershell
Copy-Item backend.hcl.example backend.hcl
Copy-Item terraform.tfvars.example terraform.tfvars
# 두 파일의 버킷 이름을 실제 값으로 수정한 후 실행합니다.
terraform init '-backend-config=backend.hcl'
terraform fmt -check -recursive
terraform validate
terraform plan
```

`terraform.tfvars`의 `avatar_bucket_name`은 **기존 사진 버킷 이름**입니다. 새 버킷 이름으로 바꾸면 리소스 교체가 계획될 수 있습니다. `plan`에서 계정, 리전과 변경 내용을 확인한 후에만 `terraform apply`를 실행합니다. 이미 존재하지만 현재 상태에 없는 버킷은 자동으로 가져오지 않으므로 별도 import 계획이 필요합니다.

상태 버킷 자체를 관리하려면 `bootstrap/`에서도 같은 `backend.hcl`을 지정해 초기화하고, `bootstrap/terraform.tfvars.example`을 복사해 동일한 상태 버킷 이름을 설정합니다.

```powershell
Copy-Item bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
# bootstrap/terraform.tfvars의 버킷 이름을 실제 상태 버킷 이름으로 수정합니다.
terraform '-chdir=bootstrap' init '-backend-config=../backend.hcl'
terraform '-chdir=bootstrap' plan
```

상태 버킷 자체의 상태도 이 버킷에 저장되므로, 버킷이나 원격 상태를 임의로 삭제하지 마세요. 버킷을 새로 만들어 초기 구축해야 한다면 별도 로컬 상태를 사용하는 부트스트랩 절차를 계획해야 합니다. 다른 환경에서 이 설정을 그대로 `apply`해 기존 버킷을 다시 만들지 않습니다.

## CI와 이슈

GitHub Actions는 push, pull request, 수동 실행 시 루트와 `bootstrap/` 각각에 대해 `terraform fmt`, 백엔드 없는 `init`, `validate`를 수행합니다. AWS 자격 증명, 원격 상태, `plan` 또는 `apply`를 사용하지 않으므로 실제 AWS 접근이나 변경은 검증하지 않습니다. `.github/ISSUE_TEMPLATE`에서 기능, 유지보수, 버그 이슈를 작성할 수 있습니다.

## 사진 접근

사진 버킷은 퍼블릭 액세스를 차단합니다. EC2 인스턴스 역할에는 사진 업로드 권한이 포함되며, 앱에서 사진을 표시하려면 CloudFront 같은 안전한 이미지 제공 방식과 `ASSETS_BASE_URL` 설정이 필요합니다. 현재 Terraform은 이미지 제공 경로나 IAM 사용자를 생성하지 않습니다.
