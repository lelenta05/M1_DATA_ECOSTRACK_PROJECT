# Valeurs actuelles
 # scripts
--SHOW ALL;

--SHOW shared_buffers;
--SHOW effective_cache_size;
# RESULTAT 
## shared_buffers:230MB; effective_cache_size:6553MB

--SHOW work_mem;
# resutat:work_men:4MB;

Rôle
Mémoire utilisée :

- pour les ORDER BY
- pour les GROUP BY
- pour les hash joins

# nb:work_mem est par opération et par requête.

Si trop faible :
- PostgreSQL fait des sorts sur disque
- Performance chute fortement
- Recommandations de configuration


## shared_buffers recommandé

Règle générale serveur dédié :

- 25% RAM
- Déjà probablement configuré ainsi.
- Non modifiable sur Supabase Free.

## work_mem recommandé

Formule importante :
### work_mem × connexions simultanées × opérations

Si :
- 20 connexions
- 2 opérations de tri
- Et work_mem = 16MB

- 20 × 2 × 16MB = 640MB
- Explosion mémoire

# Recommandation réaliste Free Tier :
work_mem = 8MB
Pour requêtes analytiques ponctuelles :

SET work_mem = '32MB';
