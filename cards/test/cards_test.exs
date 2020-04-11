defmodule CardsTest do
  use ExUnit.Case
  doctest Cards

  test "create_deck makes 20 cards" do
    deck_length = length(Cards.create_deck())
    assert deck_length == 20
  end

  test "shuffling a deck randomizes it" do
    deck = Cards.create_deck()
    refute deck == Cards.shuffle(deck)
  end

  test "create_hand deals a hand of (5) cards" do
    {hand, deck} = Cards.create_hand(5)
    assert length(hand) == 5
  end
end
