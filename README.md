# Search and remove orphaned docker volumes
Script to search and delete orphaned docker volumes

If you need to remove only orphaned volumes and keep volumes associated with stopped containers you can execute `docker volume prune`. But in my case it was important to keep more detailed information about which volumes are going to be deleted, so my approach was to save files with list of associated and orphaned volumes, based on which I made volume backups first. 
