**Why is this change necessary?**

- Users were being redirected to the home page after login, which is less
  useful than redirecting to the page they had originally requested before
  being redirected to the login form.

**How does it address the issue?**

- Introduce a red/black tree to increase search speed
- Remove _troublesome lib X_, which was causing _specific description of issue introduced by lib_;

**What side effects does this change have?**

- Requires database migration
- Requires mix task X executed;

**Task card (link)**

- [Card Title](https://bcredi.atlassian.net/browse/CRED-64)
