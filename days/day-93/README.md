# Day 93 — Ansible when Conditionals: Per-Server File Distribution

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / when Conditionals / Gathered Facts  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

One play targeting `hosts: all` — but each copy task runs only on the correct server using `when: ansible_nodename == 'stappXX'`.

| Server | File | Owner | Permissions |
|--------|------|-------|------------|
| stapp01 | blog.txt | tony | 0777 |
| stapp02 | story.txt | steve | 0777 |
| stapp03 | media.txt | banner | 0777 |

Source: `/usr/src/finance/` on jump host → Destination: `/opt/finance/` on each server

---

## 🧠 Concept — Ansible `when` Conditionals

### What is `when`?

`when` is Ansible's conditional statement. A task with `when` only executes if the condition evaluates to `True`. If `False`, the task is skipped (shown as `skipping` in output) rather than failing.

```yaml
- name: Only runs on stapp01
  copy:
    src: blog.txt
    dest: /opt/finance/blog.txt
  when: ansible_nodename == 'stapp01'
```

### `ansible_nodename` — The Gathered Fact

Ansible collects system facts at the start of each play (the "Gathering Facts" step). `ansible_nodename` contains the server's fully qualified domain name or nodename — for Stratos DC servers this matches the hostname (`stapp01`, `stapp02`, `stapp03`).

```
ansible_nodename on stapp01 → 'stapp01'
ansible_nodename on stapp02 → 'stapp02'
ansible_nodename on stapp03 → 'stapp03'
```

### Why `hosts: all` with `when` instead of separate plays?

The task requirement specifically says `hosts: all`. Using `when` conditions with `hosts: all` is one of the core Ansible conditional patterns — demonstrating that a single play can behave differently per host based on facts. The alternative (separate plays per host) works but doesn't use `when` conditionals.

### Execution Flow

```
Play: hosts: all
  Task: Create /opt/finance directory
    → runs on stapp01 ✅
    → runs on stapp02 ✅
    → runs on stapp03 ✅

  Task: Copy blog.txt (when: stapp01)
    → runs on stapp01  ✅ (condition True)
    → skips on stapp02 ⏭ (condition False)
    → skips on stapp03 ⏭ (condition False)

  Task: Copy story.txt (when: stapp02)
    → skips on stapp01 ⏭
    → runs on stapp02  ✅
    → skips on stapp03 ⏭

  Task: Copy media.txt (when: stapp03)
    → skips on stapp01 ⏭
    → skips on stapp02 ⏭
    → runs on stapp03  ✅
```

---

## 🔧 The Playbook

```yaml
---
- name: Copy files to app servers using when conditionals
  hosts: all
  become: yes
  tasks:
    - name: Create /opt/finance directory on all servers
      file:
        path: /opt/finance
        state: directory

    - name: Copy blog.txt to App Server 1 (stapp01)
      copy:
        src: /usr/src/finance/blog.txt
        dest: /opt/finance/blog.txt
        owner: tony
        group: tony
        mode: '0777'
      when: ansible_nodename == 'stapp01'

    - name: Copy story.txt to App Server 2 (stapp02)
      copy:
        src: /usr/src/finance/story.txt
        dest: /opt/finance/story.txt
        owner: steve
        group: steve
        mode: '0777'
      when: ansible_nodename == 'stapp02'

    - name: Copy media.txt to App Server 3 (stapp03)
      copy:
        src: /usr/src/finance/media.txt
        dest: /opt/finance/media.txt
        owner: banner
        group: banner
        mode: '0777'
      when: ansible_nodename == 'stapp03'
```

---

## 🔧 Commands on Jump Host

```bash
# Verify source files exist
ls /usr/src/finance/
# Expected: blog.txt  story.txt  media.txt

# Create playbook
cat > /home/thor/ansible/playbook.yml << 'EOF'
[paste playbook content]
EOF

# Run
cd /home/thor/ansible
ansible-playbook -i inventory playbook.yml

# Verify results
ansible stapp01 -i inventory -m shell \
  -a "ls -la /opt/finance/blog.txt" --become
ansible stapp02 -i inventory -m shell \
  -a "ls -la /opt/finance/story.txt" --become
ansible stapp03 -i inventory -m shell \
  -a "ls -la /opt/finance/media.txt" --become
```

**Expected PLAY RECAP:**
```
stapp01 : ok=3  changed=2  skipped=2  failed=0
stapp02 : ok=3  changed=2  skipped=2  failed=0
stapp03 : ok=3  changed=2  skipped=2  failed=0
```

Notice `skipped=2` per host — two of the three copy tasks are skipped on each server.

---

## ⚠️ Common Mistakes to Avoid

1. **Using `hosts: stapp01` instead of `hosts: all`** — The task specifically requires `hosts: all`. The `when` conditionals handle the per-server targeting.
2. **Wrong fact variable** — The note specifies `ansible_nodename`. Other variables like `inventory_hostname` also work but the task wants `ansible_nodename` specifically.
3. **`gather_facts: no`** — `ansible_nodename` is a gathered fact. If `gather_facts: no` is set, the variable is undefined and `when` evaluates to False for all hosts — no files get copied.
4. **Forgetting to create the destination directory** — `copy` fails if `/opt/finance/` doesn't exist. The `file: state: directory` task must run on all hosts before the copy tasks.
5. **Wrong owner per server** — tony for stapp01, steve for stapp02, banner for stapp03. Mixing these up fails validation.

---

## 💼 Real-World DevOps Q&A

**Q1: What is the Ansible `when` conditional and how does it differ from using separate plays?**

`when` adds a condition to a task — the task executes only when the condition evaluates to True, otherwise it's skipped. Using `when` with `hosts: all` in a single play is more expressive than separate plays per host: it runs the same connection setup once per host and shows all tasks in a single play output, making it easier to see the full execution picture. Separate plays are cleaner when the differences between hosts are extensive (different tasks, not just different files). `when` is better for "same task type, different parameters per host" scenarios.

**Q2: What is `ansible_nodename` and how is it gathered?**

`ansible_nodename` is a system fact Ansible collects during the "Gathering Facts" step at the start of each play. Ansible connects to the managed host and runs a Python-based facts module that collects dozens of system attributes: OS family, distribution, IP addresses, hostname, memory, CPU architecture. `ansible_nodename` specifically contains the system's fully qualified domain name (FQDN) as returned by `uname -n`. It's available in all tasks within the play as a variable without any import or declaration.

**Q3: What other facts could be used instead of `ansible_nodename` for host-based conditionals?**

Several facts work for host identification:
- `ansible_hostname` — short hostname (without domain)
- `ansible_nodename` — FQDN or full nodename
- `inventory_hostname` — the name used in inventory (not a gathered fact)
- `ansible_fqdn` — fully qualified domain name
- `ansible_default_ipv4.address` — primary IP address

`inventory_hostname` is technically not a gathered fact (it's always available regardless of `gather_facts` setting) and is often the most reliable for host targeting since it matches exactly what's in your inventory file.

**Q4: How would you simplify this playbook using a dictionary variable instead of three separate copy tasks?**

```yaml
---
- name: Copy files using vars and when
  hosts: all
  become: yes
  vars:
    file_map:
      stapp01: {file: blog.txt,  owner: tony}
      stapp02: {file: story.txt, owner: steve}
      stapp03: {file: media.txt, owner: banner}
  tasks:
    - name: Create /opt/finance
      file:
        path: /opt/finance
        state: directory

    - name: Copy file to respective server
      copy:
        src: "/usr/src/finance/{{ file_map[ansible_nodename].file }}"
        dest: "/opt/finance/{{ file_map[ansible_nodename].file }}"
        owner: "{{ file_map[ansible_nodename].owner }}"
        group: "{{ file_map[ansible_nodename].owner }}"
        mode: '0777'
      when: ansible_nodename in file_map
```

One task instead of three — the dictionary drives the behavior. More maintainable as the server count grows.

**Q5: What does `skipped` mean in the PLAY RECAP and is it a problem?**

`skipped` in the PLAY RECAP counts tasks that were skipped due to `when` conditions evaluating to False. It's completely normal and expected — it means the task was evaluated, the condition was False, and the task was intentionally not executed. `skipped` is not an error. On stapp01, two of the three copy tasks will show as skipped (story.txt and media.txt). This is the correct behavior showing that `when` conditionals are working as designed.

---

## 🔗 References

- [Ansible Conditionals](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html)
- [Ansible Gathered Facts](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html)
- [Ansible `copy` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
