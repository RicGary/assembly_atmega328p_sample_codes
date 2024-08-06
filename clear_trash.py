import os

def delete_files_with_extensions(directory, extensions):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(tuple(extensions)):
                os.remove(os.path.join(root, file))

# Specify the directories to clean up
cur_dir = os.getcwd()  # Current directory
directories = [
    cur_dir,
    f"{cur_dir}/atividades de aula",
    f"{cur_dir}/code_sample",
    f"{cur_dir}/old"
]

# Specify the file extensions to delete
extensions = [".ist", ".pro", ".err", ".asm~", ".lst", ".hex"]

# Delete the files with the specified extensions in the directories
for directory in directories:
    delete_files_with_extensions(directory, extensions)