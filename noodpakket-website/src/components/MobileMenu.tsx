import { Menu } from "lucide-react";
import { Sheet, SheetClose, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

type Item = { href: string; label: string };

export default function MobileMenu({ items, current }: { items: Item[]; current: string }) {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <button
          type="button"
          aria-label="Menu openen"
          className="inline-flex h-[48px] w-[48px] shrink-0 items-center justify-center rounded-xl border border-border bg-card text-foreground lg:hidden"
        >
          <Menu className="size-6" aria-hidden="true" />
        </button>
      </SheetTrigger>
      <SheetContent side="right" className="w-[min(22rem,90vw)] gap-0 bg-background p-0">
        <SheetHeader className="p-5">
          <SheetTitle className="font-heading text-lg">Menu</SheetTitle>
          <SheetDescription className="sr-only">Navigatie van NL-Noodpakket</SheetDescription>
        </SheetHeader>
        <nav aria-label="Hoofdmenu" className="flex flex-col px-3 pb-6">
          {items.map((item) => (
            <SheetClose asChild key={item.href}>
              <a
                href={item.href}
                aria-current={item.href === current ? "page" : undefined}
                className="flex min-h-12 items-center rounded-xl px-4 text-lg font-medium no-underline hover:bg-muted aria-[current=page]:bg-primary-soft aria-[current=page]:text-primary"
              >
                {item.label}
              </a>
            </SheetClose>
          ))}
        </nav>
      </SheetContent>
    </Sheet>
  );
}
