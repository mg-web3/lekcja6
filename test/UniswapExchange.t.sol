// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IUniswapExchange} from "../src/interfaces/IUniswapExchange.sol";
import {UniswapFactory} from "../src/UniswapFactory.sol";
import {ERC20Mock} from "./MockERC20.sol";

contract UniswapExchangeTest is Test {
    UniswapFactory public factory;
    ERC20Mock public token1;
    ERC20Mock public token2;
    address public bob = address(1);
    address public alice = address(2);

    function setUp() public {
        factory = new UniswapFactory();

        token1 = new ERC20Mock();
        token2 = new ERC20Mock();

        vm.deal(bob, 1 ether);
        vm.deal(alice, 1 ether);

        token1.mint(bob, 1 ether);
        token1.mint(alice, 1 ether);
    }

    function test_createExchange() public {
        address payable addr_exchange = factory.createExchange(address(token1));
        IUniswapExchange exchange = IUniswapExchange(addr_exchange);

        assertEq(addr_exchange, factory.getExchange(address(token1)));
        assertEq(factory.getToken(addr_exchange), address(token1));
        assertEq(factory.getTokenWithId(1), address(token1));
        assertEq(0, exchange.totalSupply());
        assertEq(address(factory), exchange.factoryAddress());

        vm.expectRevert();
        factory.createExchange(address(token1));
    }

    function test_createTwoExchanges() public {
        address payable addr_exchange1 = factory.createExchange(
            address(token1)
        );
        IUniswapExchange exchange1 = IUniswapExchange(addr_exchange1);
        address payable addr_exchange2 = factory.createExchange(
            address(token2)
        );
        IUniswapExchange exchange2 = IUniswapExchange(addr_exchange2);

        assertEq(addr_exchange1, factory.getExchange(address(token1)));
        assertEq(factory.getToken(addr_exchange1), address(token1));
        assertEq(factory.getTokenWithId(1), address(token1));
        assertEq(0, exchange1.totalSupply());
        assertEq(address(factory), exchange1.factoryAddress());

        assertEq(addr_exchange2, factory.getExchange(address(token2)));
        assertEq(factory.getToken(addr_exchange2), address(token2));
        assertEq(factory.getTokenWithId(2), address(token2));
        assertEq(0, exchange2.totalSupply());
        assertEq(address(factory), exchange2.factoryAddress());
    }

    function test_add_liquidity() public {
        vm.startPrank(bob);
        address payable addr_exchange = factory.createExchange(address(token1));
        IUniswapExchange exchange = IUniswapExchange(addr_exchange);

        assertEq(exchange.balanceOf(bob), 0);
        assertEq(token1.balanceOf(addr_exchange), 0);

        token1.approve(addr_exchange, 1 ether);
        exchange.addLiquidity{value: 5 gwei}(0, 5 gwei, block.timestamp + 1);

        assertGt(exchange.totalSupply(), 0);
        assertGt(exchange.balanceOf(bob), 0);
        assertEq(token1.balanceOf(addr_exchange), 5 gwei);
        assertEq(bob.balance, 1 ether - 5 gwei);
    }

    function test_swap_default() public {
        // stwórz giełdę
        vm.startPrank(bob);
        address payable addr_exchange = factory.createExchange(address(token1));
        IUniswapExchange exchange = IUniswapExchange(addr_exchange);

        // dodaj płynność
        token1.approve(addr_exchange, 1 ether);
        exchange.addLiquidity{value: 5 gwei}(0, 5 gwei, block.timestamp + 1);
        console2.log("--- przed ---");
        console2.log(
            "k = ",
            addr_exchange.balance * token1.balanceOf(addr_exchange)
        );
        console2.log("eth w LP: ", addr_exchange.balance);
        console2.log("token1 w LP: ", token1.balanceOf(addr_exchange));

        // wymień eth na token poprzez przesłanie eth na adres giełdy
        vm.startPrank(alice);
        addr_exchange.call{value: 1 gwei}("");

        // sprawdź
        console2.log("--- po ---");
        console2.log(
            "k = ",
            addr_exchange.balance * token1.balanceOf(addr_exchange)
        );
        console2.log("eth w LP: ", addr_exchange.balance);
        console2.log("token1 w LP: ", token1.balanceOf(addr_exchange));
        assertGt(token1.balanceOf(alice), 1 ether);
        assertEq(alice.balance, 1 ether - 1 gwei);
    }

    function test_impermanent_loss() public {
        // stwórz giełdę
        vm.startPrank(bob);
        address payable addr_exchange = factory.createExchange(address(token1));
        IUniswapExchange exchange = IUniswapExchange(addr_exchange);

        // dodaj płynność przy cenie 1 eth = 1 token1 oraz 1 eth = 1000 usd
        console2.log(
            "[t0] Wartosc portfela boba (w usd): ",
            (bob.balance * 1000 + token1.balanceOf(bob) * 1 * 1000) / 10 ** 18
        );
        token1.approve(addr_exchange, 1 ether);
        exchange.addLiquidity{value: 1 ether}(0, 1 ether, block.timestamp + 1);
        console2.log(
            "[t0] Cena token1/ether: ",
            (token1.balanceOf(addr_exchange) * 100) / addr_exchange.balance
        );

        // cena rynkowa eth względem token1 rośnie -> 1 eth = 1.4 token1
        // alice korzysta na szansie arbitrazowej czyli kupuje na innej giełdzie gdzie cena rynkowa jest juz odzwierciedlona token1, i sprzedaje go na naszej giełdzie, poniewaz tu token1 cały czas warty jest 1 eth
        vm.startPrank(alice);
        token1.approve(addr_exchange, 1 ether);
        exchange.tokenToEthSwapInput(0.08 ether, 1, block.timestamp + 1);
        console2.log(
            "[t1] Cena token1/ether: ",
            (token1.balanceOf(addr_exchange) * 100) / addr_exchange.balance
        );

        // cena na naszej giełdzie po operacji alice cały czas nie odpowiada 1 eth = 1.4 token1 (tylko 1 eth = 1.16 token1)
        // alice ponownie korzysta na szansie arbitrazowej czyli kupuje na innej giełdzie gdzie cena rynkowa jest juz odzwierciedlona token1, i sprzedaje go na naszej giełdzie
        exchange.tokenToEthSwapInput(0.08 ether, 1, block.timestamp + 1);
        console2.log(
            "[t2] Cena token1/ether: ",
            (token1.balanceOf(addr_exchange) * 100) / addr_exchange.balance
        );
        // załózmy ze w między czasie ceny na innych giełdach spadły do 1.34 token1 = 1 eth czyli mamy równowagę i brak szans na arbitraz
        // natomiast wartość samego eth w dolarzach nie zmieniła się, czyli 1 eth = 1000 usd, wiec 1 token1 = 1000 / 1.34 =  746 usd
        // bob chce wycofać swoje tokeny z puli płynności
        vm.startPrank(bob);
        exchange.removeLiquidity(
            exchange.balanceOf(bob),
            1,
            1,
            block.timestamp + 1
        );
        console2.log("[t2] Ilosc ethera: ", bob.balance);
        console2.log("[t2] Ilosc token1: ", token1.balanceOf(bob));
        console2.log(
            "[t2] Wartosc portfela boba (w usd): ",
            (bob.balance * 1000 + (token1.balanceOf(bob) * 746)) / 10 ** 18
        );
        console2.log(
            "[alt] Wartosc portfela boba (w usd): ",
            uint256(1000) + 746
        );
        console2.log(
            "[t2] Wartosc portfela alice (w usd): ",
            (alice.balance * 1000 + (token1.balanceOf(alice) * 746)) / 10 ** 18
        );
    }
}
