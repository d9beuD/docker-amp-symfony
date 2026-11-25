<?php

// Copied to src/Command/ by init-symfony.sh, the prod image's entrypoint

namespace App\Command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand('app:entrypoint', 'Prepares the app, then replaces itself with the given server command')]
final class EntrypointCommand extends Command
{
    protected function configure(): void
    {
        $this->addArgument('server', InputArgument::IS_ARRAY | InputArgument::REQUIRED, 'Absolute path of the server binary, then its arguments');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $application = $this->getApplication();
        $steps = [['command' => 'cache:warmup']];
        // Not every project installs Doctrine Migrations
        if ($application->has('doctrine:migrations:migrate')) {
            $steps[] = ['command' => 'doctrine:migrations:migrate', '--allow-no-migration' => true];
        }

        foreach ($steps as $arguments) {
            $step = new ArrayInput($arguments);
            $step->setInteractive(false);
            if (0 !== $code = $application->doRun($step, $output)) {
                return $code;
            }
        }

        // Like `exec "$@"` in a shell: the server takes over this process and gets the signals
        $server = $input->getArgument('server');
        pcntl_exec($server[0], \array_slice($server, 1));
        $output->writeln(\sprintf('<error>Could not exec %s: %s</error>', $server[0], pcntl_strerror(pcntl_get_last_error())));

        return Command::FAILURE;
    }
}
