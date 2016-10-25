# NeesanQuest

The NeesanQuest repo!
(last updated 2016-10-24)

Some tips for working smoothly:

- Always sync before starting work. Also, notify others when you start to work on something to avoid conflicts, which *will* happen since that's just how RPG Maker does things. Most importantly, new maps should not be created by two people at the same time as map data files are named automatically in ascending order (Map001 is the first map you make, the second map is Map002 regardless of its name, etc.). This can cause problems and serious setbacks.

- When doing work inside RPG Maker: after syncing, run 01ToRPG.bat to pack the YAML plaintext files in the YAML folder into binary stuff so that you may open the project. When you're done making changes, save your work and run 02ToCommit.bat, which does the reverse operation and unpacks everything in the Data folder to plaintext in the YAML folder. You may now commit and sync these files.

- As a result of committing plaintext files instead of the .rvdata2 files, the Data folder is no longer required to be part of commits and has been added to .gitignore.