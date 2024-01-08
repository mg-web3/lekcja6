# Programowanie Web3 - Fundamenty Blockchain i Solidity

Lekcja 6 kursu Programowanie Web3 - Fundamenty Blockchain i Solidity.

Zdecentralizowane Finanse.

![DeFi](6-defi.png)

## Instalacja i konfiguracja

1. Stwórz folder dla projektu i przejdź do niego: `mkdir nazwa-projektu` i `cd nazwa-projektu`
2. Stwórz nowy projekt Foundry: `forge init`
3. Zainstaluj biblioteki od OpenZeppelin i FoundryRandom: `forge install Openzeppelin/openzeppelin-contracts`
4. Do pliku `foundry.toml` dodaj linijkę, która pozwoli kompilatorowi na poprawne mapowanie zależności: `remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]`
5. Usuń pliki : `rm src/Counter.sol`, `rm test/Counter.t.sol` i kolejno `rm script/Counter.s.sol`
6. Przekopiuj z repozytorium https://github.com/PhABC/uniswap-solidity pliki źródłowe kontraktów + bibliotekę SafeMath
7. Zaktualizuj kod z Soldiity 0.5 na 0.8
8. Stwórz testy

## Uruchomienie

1. Skompiluj kod: `forge build`
2. Uruchom testy: `forge test -vvvv` (czym więcej 'v' tym bardziej szczegółowe logowanie)

## Attributions

Based on a Github repo from Philippe Castonguay located at: https://github.com/PhABC/uniswap-solidity. Original Uniswap v1 code: https://github.com/Uniswap/v1-contracts/blob/master/contracts/uniswap_factory.vy.
