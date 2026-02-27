# Example: Integrating an AI-Analytics Module

## Input Request
"User: I need to add a new service named 'alchemist-ai' to process chatbot sentiment metrics. It needs a volume for data and must be on the secure-net."

## Before Architecture (Entropy Concentration)
- The user might try to add a standalone container without network isolation or volume standard naming.

## After Architecture (Architectural Symmetry)
The Sentinel Architect follows the **Axioms of Expansion**:
1. **Directory**: Creates `modules/04-analytics/`.
2. **Standardization**: Names the container `app_alchemist`.
3. **Topology**:
   ```yaml
   services:
     app_alchemist:
       image: alchemist-ai:latest
       networks:
         - secure-net
       volumes:
         - ./persistence/analytics-data:/data
   ```
4. **Verification**: Updates `references/topology_rules.md` to include the new node and its Health Index (`/health/sentiment`).
