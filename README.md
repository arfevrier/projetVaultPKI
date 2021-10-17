# Projet d'intégration d'une PKI Vault 🔐

![vault-img](https://user-images.githubusercontent.com/23292338/137619469-ea19821c-7f2d-4cef-b1c7-d93a085c2c64.png)

## 1 - Mise en place d'une autorité de certification SSH

Dans un système d’information l’utilisation de SSH est omniprésente pour administrer les nombreux serveurs présents dans une le système. Lorsque le nombre de serveurs et d’utilisateurs commence à augmenter, il devient extrêmement difficile de pouvoir connaître les rôles, besoins, et autorisation de chaque utilisateur sur chacun des systèmes. Originalement chaque serveur possède une liste des clés utilisateurs autorisés à accéder au terminal. Réaliser un audit global de l’ensemble du système d'information est fastidieux.

De plus, les administrateurs systèmes peuvent être confrontés à de nombreux problèmes. Les utilisateurs perdent leur clé SSH, il faut les modifier sur l’ensemble des serveurs. Le roulement des clés SSH est lent. Chaque utilisateur ne doit pouvoir accéder qu'à certain groupe de serveur spécifiquement.

Une solution est de mettre en place une autorité de certification donnant les autorisations aux utilisateurs qui en ont le droit.

Pour cela, nous allons utiliser Vault. Vault est un outil qui permet de stocker en toute sécurité des secrets. Les secrets correspondant à des données sensibles nécessitent un contrôle fin sur leur accès en lecture, comme les clés d’API, les mots de passe, les certificats, etc.

Vault n’est pas qu’un simple stockage, il gère l’ensemble du cycle de vie de vos secrets. Il peut générer des secrets à la demande pour certains systèmes, tels que les bases de données. Par exemple, Vault peut générer et révoquer également automatiquement vos certificats. De manière générale, dans vault tous les secrets de Vault sont associés à un bail. À la fin du bail, Vault révoquera automatiquement ces secrets.

Le moteur de secrets SSH de Vault fournit une authentification et une autorisation sécurisées pour l'accès aux machines via le protocole SSH. Le moteur de secrets SSH de Vault permet de gérer l'accès à l'infrastructure des machines, en fournissant plusieurs moyens d'émettre des informations d'identification SSH.

Le but final du projet est de pouvoir avoir une vision globale de l’ensemble des autorisations de chaque utilisateur et pouvoir auditer l’ensemble des accès SSH de manière centralisée.

### ➔ Schéma de fonctionnement du SSH Engine Vault ⛓️

Le principe d’une infrastructure à clé publique repose sur l’utilisation de la cryptographie asymétrique. Une infrastructure de gestion de clés permet de lier des clés publiques à des identités (comme des utilisateurs). Une infrastructure de gestion de clés fournit des garanties permettant de faire a priori confiance à une clé publique obtenue par son biais.

Vault possède une autorité de Certification (CA) qui est un tiers de confiance permettant d'authentifier l'identité des correspondants. Une autorité de certification délivre des certificats décrivant des identités numériques et met à disposition les moyens de vérifier la validité des certificats qu'elle a fournis par cryptographie.
Chaque serveur SSH possède le certificat Vault CA. Ainsi chaque serveur reconnaît Vault comme un tier de confiance. 

![SSH_engine_vault](https://user-images.githubusercontent.com/23292338/137619295-0556ba7a-6cf9-4413-bd96-dcc979ad8a4a.png)

### ➔ Installation ⚙️

1. Télécharger le code
   ```bash
   git clone https://github.com/arnicel/projetVaultPKI.git
   ```
2. Mettre à jour les paramètres Ansible:
   (`deployement/group_vars`) et (`deployement/hosts`)
3. Déployer le serveur vault
   ```bash
   ansible-playbook -i deployement/hosts deployement/site.yml --ask-pass -K
   ```
4. Configuration de vault
   ```bash
   cd configuration
   terraform apply
   ```


# Ressource 📚

Liste des ressources utilisées pour mener à bien le projet:
* [Signed SSH Certificates / vaultproject.io](https://www.vaultproject.io/docs/secrets/ssh/signed-ssh-certificates)
* [HashiCorp Vault setup SSH Authentication with Ansible and Terraform / infralovers.com](https://www.infralovers.com/en/articles/2021/03/03/hashicorp-vault-and-ssh-with-ansibleterraform/)
* [Using Vault as an SSH certificate authority / brian-candler.medium.com](https://brian-candler.medium.com/using-hashicorp-vault-as-an-ssh-certificate-authority-14d713673c9a)
* [Ansible Documentation](https://docs.ansible.com/)
* [Documentation Vault Provider / terraform.io](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
