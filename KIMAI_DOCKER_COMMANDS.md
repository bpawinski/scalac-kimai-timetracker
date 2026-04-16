# Kimai Docker Commands - Quick Reference

## Setup & Installation

```bash
# Stwórz folder projektu
mkdir ~/kimai-local

# Wejdź do folderu
cd ~/kimai-local

# Otwórz w VS Code
code .
```

## Docker Compose - Basic Commands

```bash
# Start kontenery (w tle)
docker-compose up -d

# Zatrzymaj kontenery (bez usuwania danych!)
docker-compose down

# Zatrzymaj + usuń WSZYSTKO (baza, volumy, etc)
docker-compose down -v

# Sprawdzenie statusu kontenerów
docker-compose ps

# Sprawdzenie wersji Kimai
docker --version
```

## Logi & Debugging

```bash
# Logi z Kimai (live, ostatnie 50 linii)
docker-compose logs kimai | tail -50

# Logi z Kimai (live stream)
docker-compose logs -f kimai

# Logi z MySQL
docker-compose logs -f mysql

# Logi z oboma kontenerami
docker-compose logs -f

# Wyjście z live logs
Ctrl+C
```

## Kimai Access

```bash
# Otwórz w przeglądarce
http://localhost:8001

# Login credentials (default)
Email: admin@kimai.local
Password: admin123
```

## Database - MySQL

```bash
# Dostęp do MySQL (jeśli potrzebujesz)
Host: localhost
Port: 3306
User: kimai
Password: kimai_mysql_password_123
Database: kimai
```

## Claude Code Integration

```bash
# Sprawdzenie statusu Docker'a
claude "check docker status"

# Logi Kimai
claude "show docker logs for kimai"

# Restart kontenerów
claude "restart docker containers"

# Zmiana docker-compose.yml
claude "update docker-compose.yml to [twoja zmiana]"
```

## Troubleshooting

```bash
# Jeśli port 8001 jest zajęty - zmień w docker-compose.yml
# Zmień: ports: - "8001:8001" na "8002:8001"

# Jeśli coś poszło nie tak - pełny reset
docker-compose down -v
docker-compose up -d

# Czyszczenie Docker cache
docker system prune -a

# Sprawdzenie zajętych portów (Mac)
lsof -i :8001
```

## Przydatne

```bash
# Gdzie jestem
pwd

# Lista plików w folderze
ls -la

# Edycja docker-compose.yml w terminalu
nano docker-compose.yml

# Zapisz w nano
Ctrl+O → Enter

# Wyjście z nano
Ctrl+X

# Zmień hasło admin w Kimai
# Administration > Users > Edit admin > Change password
```

## Full Workflow

1. **Setup** (pierwszy raz)
   ```bash
   mkdir ~/kimai-local
   cd ~/kimai-local
   code .
   # Utwórz docker-compose.yml i dodaj zawartość
   docker-compose up -d
   ```

2. **Daily Usage**
   ```bash
   # Start
   docker-compose up -d
   
   # Pracuj
   http://localhost:8001
   
   # Stop (bez utraty danych)
   docker-compose down
   ```

3. **Debugging**
   ```bash
   docker-compose ps          # Status
   docker-compose logs kimai  # Logi
   docker-compose down -v     # Hard reset
   ```

## Struktura Projektu

```
~/kimai-local/
├── docker-compose.yml      ← główny plik konfiguracji
├── KIMAI_DOCKER_COMMANDS.md ← ten plik (quick reference)
└── .gitignore             ← (opcjonalnie) ignoruj volumy
```

## Szybkie Shortcuts

```bash
# Alias (dodaj do ~/.zshrc lub ~/.bash_profile)
alias kimai-start='cd ~/kimai-local && docker-compose up -d'
alias kimai-stop='cd ~/kimai-local && docker-compose down'
alias kimai-logs='cd ~/kimai-local && docker-compose logs -f kimai'
alias kimai-reset='cd ~/kimai-local && docker-compose down -v && docker-compose up -d'
```

---

**Tip:** Trzymaj ten plik w projekcie (~/kimai-local/) aby zawsze miał dostęp!
