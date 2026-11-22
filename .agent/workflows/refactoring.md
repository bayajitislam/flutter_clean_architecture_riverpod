# Refactoring

1. State the behavior that must stay the same.
2. Cover that behavior with a test before moving code.
3. Move one layer at a time. Keep the public repository and use case signatures stable unless the task changes them.
4. Delete the old file only after every import points at the new one.
5. Run the full test suite, not only the file you moved.

Do not rename the package, change the folder architecture, or swap Riverpod, GoRouter, or Dio as part of a local refactor.
