sudo useradd -s /sbin/nologin rose
grep "rose" /etc/passwd
```

Verified with `sudo su - rose` → *"This account is currently not available."* ✅


