import pytest

from app.web_article import (
    WebArticleError,
    _ensure_public_destination,
    extract_web_article,
)


def _paragraph(sentence: str, count: int = 12) -> str:
    return " ".join([sentence] * count)


def test_extracts_article_text_and_removes_page_chrome() -> None:
    article = extract_web_article(
        f"""
        <html>
          <head><title>La vie du quartier</title><script>ignore me</script></head>
          <body>
            <nav>Accueil Abonnement Contact</nav>
            <main>
              <article>
                <h1>Une nouvelle bibliothèque</h1>
                <p>{_paragraph("La bibliothèque accueille les habitants du quartier.")}</p>
              </article>
            </main>
            <footer>Copyright et liens inutiles</footer>
          </body>
        </html>
        """,
        "https://example.com/culture/bibliotheque",
    )

    assert article.title == "La vie du quartier"
    assert "Une nouvelle bibliothèque" in article.text
    assert "accueille les habitants" in article.text
    assert "Accueil Abonnement" not in article.text
    assert "ignore me" not in article.text
    assert article.was_truncated is False


def test_rejects_a_short_or_navigation_only_page() -> None:
    with pytest.raises(WebArticleError) as captured:
        extract_web_article(
            "<html><body><nav>Home News Contact</nav><p>Bonjour.</p></body></html>",
            "https://example.com",
        )

    assert captured.value.code == "article_too_short"


def test_identifies_a_common_paywall_page() -> None:
    with pytest.raises(WebArticleError) as captured:
        extract_web_article(
            "<html><body><main><p>Abonnez-vous pour lire "
            + _paragraph("ce contenu réservé aux abonnés", 8)
            + "</p></main></body></html>",
            "https://example.com/article",
        )

    assert captured.value.code == "article_paywalled"


@pytest.mark.asyncio
async def test_rejects_private_network_destinations() -> None:
    with pytest.raises(WebArticleError) as captured:
        await _ensure_public_destination("http://127.0.0.1/private")

    assert captured.value.code == "unsafe_url"
